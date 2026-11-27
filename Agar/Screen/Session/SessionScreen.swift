//
//  SessionScreen.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI
import SwiftData

struct SessionScreen: View {
    @Environment(BluetoothViewModel<ElectrodeSensor>.self) var bluetoothVM
    @Environment(FreshnessViewModel.self) var freshnessVM
    @Environment(PageStateViewModel.self) var pageStateVM
    @Environment(RecapViewModel.self) var recapVM
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @State var sessionVM: SessionViewModel
    @State private var showSessionList = false
    // a scan the grade can't be trusted for, the user has to stab again
    @State private var scanMessage: String?
    // ripple fill for the hold-to-end button, 0...1
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdTick = 0
    @State private var holdEnded = false

    private let holdDuration: Double = 2
        
    var session: ScanSession
    
    init(session: ScanSession) {
        self.session = session
        self._sessionVM = State(initialValue: SessionViewModel(session: session))
    }
    
    var riwayatSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                SessionTotalsCard(session: sessionVM.session, countSize: 56)

                // newest scan on top, the way the mock reads. sorted rather than reversed:
                // swiftdata does not promise an order for a to-many relationship, so
                // reversing it only reversed whatever order the store happened to hand back
                RecordTable(
                    records: sessionVM.session.records.sorted { $0.scannedAt > $1.scannedAt },
                    onDelete: modelContext.delete
                )
            }
            .animation(.default, value: sessionVM.session.totalCount)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.surfaceCream)
            .navigationTitle("Riwayat Pemeriksaan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showSessionList = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    var body: some View {
        VStack() {
            machinePanel
                .toolbar{
                    ToolbarItem(placement: .topBarLeading){
                        sessionHeader
                    }
                    .sharedBackgroundVisibility(.hidden)

                    ToolbarItem (placement: .topBarTrailing){
                        Button{
                            showSessionList = true
                        }label:{
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                }
                .sheet(isPresented: $showSessionList){
                    riwayatSheet
                }
        }
        // the panel takes the whole height rather than hugging its content, so its foot
        // and the action sitting on it land in the same place on every machine state
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceCream.ignoresSafeArea())
        .onChange(of: bluetoothVM.state) { _, state in
            sessionVM.connection(state)
        }
        .onChange(of: bluetoothVM.characteristics.count) {
            guard let row = bluetoothVM.characteristics.last else { return }
            print("[row] ohm \(row.ohm) chicken \(row.chicken)")

            guard sessionVM.collect(row) else { return }
            freshnessVM.scan(sessionVM.stabRows)

            switch freshnessVM.state {
            case .scanned(let freshness):
                sessionVM.record(freshness)
            case .error(let message):
                scanMessage = message
            case .idle:
                break
            }
        }
        .alert(
            "Coba Tusuk Lagi",
            isPresented: Binding(get: { scanMessage != nil }, set: { if !$0 { scanMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(scanMessage ?? "")
        }
        .task {
            await bluetoothVM.connect()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, !bluetoothVM.isLive else { return }
            Task { await bluetoothVM.connect() }
        }
        // buzz on a bad bird, the verdict is easy to miss over machine noise
        .sensoryFeedback(.error, trigger: sessionVM.machineState) { _, state in
            if case .result(_, .notFresh) = state { true } else { false }
        }
        .bottomAction {
            // nothing to end while the machine is still coming up, so it is invisible and
            // untouchable rather than absent: dropping it outright let the panel above grow
            // into the gap, which moved the action sitting at the foot of that panel
            let title = isHolding || holdEnded ? "Terus Tahan…" : "Tahan Untuk Akhiri Sesi"

            Group {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .contentTransition(.opacity)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background {
                        // red sweeps in from the left over the hold
                        Rectangle()
                            .fill(Color.notFreshRed)
                            .scaleEffect(x: holdProgress, anchor: .leading)
                            .clipShape(.capsule)
                    }
                    // the letters turn white exactly where the red has reached. switching the
                    // whole label on holdProgress > 0 fed a Color into the two second linear
                    // animation, so it crawled through grey the entire hold
                    .overlay {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .mask {
                                Rectangle().scaleEffect(x: holdProgress, anchor: .leading)
                            }
                    }
                    // glass goes on last so it sits behind the sweep: under the glass the red
                    // came through blurred and washed out
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .contentShape(.capsule)
                    .scaleEffect(isHolding ? 0.96 : 1)
                    .animation(.spring(duration: 0.25), value: isHolding)
                    .onLongPressGesture(minimumDuration: holdDuration) {
                        holdEnded = true
                        holdProgress = 1
                        isHolding = false
                        holdTick = 0
                        Task {
                            try? await Task.sleep(for: .milliseconds(250))
                            pageStateVM.setState(.summary(sessionVM.endSession()))
                            holdEnded = false
                            holdProgress = 0
                        }
                    } onPressingChanged: { pressing in
                        guard !holdEnded else { return }
                        isHolding = pressing
                        if !pressing { holdTick = 0 }
                        withAnimation(pressing ? .linear(duration: holdDuration) : .easeOut(duration: 0.2)) {
                            holdProgress = pressing ? 1 : 0
                        }
                    }
            }
            .task(id: isHolding) {
                guard isHolding else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(250))
                    guard !Task.isCancelled, isHolding else { return }
                    holdTick += 1
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: isHolding) { _, holding in holding }
            .sensoryFeedback(trigger: holdTick) { _, tick in
                tick > 0 ? .impact(flexibility: .solid, intensity: min(1, 0.3 + Double(tick) * 0.09)) : nil
            }
            .sensoryFeedback(.success, trigger: holdEnded) { _, ended in ended }
            .opacity(sessionVM.canEndSession ? 1 : 0)
            .allowsHitTesting(sessionVM.canEndSession)
        }
    }
}


// the previews run off FakeBluetoothManager, which only exists in a Debug build
#if DEBUG
#Preview("Preparing") {
    SessionScreen(session: ScanSession(number: 1))
    .environment(BluetoothViewModel<ElectrodeSensor>(bluetoothManager: FakeBluetoothManager()))
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
    .modelContainer(for: ScanSession.self, inMemory: true)
}

#Preview("Ready") {
    SessionScreen(session: ScanSession(number: 1))
    .environment(BluetoothViewModel<ElectrodeSensor>(bluetoothManager: FakeBluetoothManager()))
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
    .modelContainer(for: ScanSession.self, inMemory: true)
}

#Preview("Scanning") {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>(bluetoothManager: FakeBluetoothManager()))
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
    .modelContainer(for: ScanSession.self, inMemory: true)
}

#Preview("Fresh") {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    let result = ScanRecord(chickenNumber: 61, freshness: .fresh)

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>(bluetoothManager: FakeBluetoothManager()))
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
    .modelContainer(for: ScanSession.self, inMemory: true)
}

#Preview("Next Chicken") {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>(bluetoothManager: FakeBluetoothManager()))
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
    .modelContainer(for: ScanSession.self, inMemory: true)
}

#Preview("Not Fresh") {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    let result = ScanRecord(chickenNumber: 61, freshness: .notFresh)

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>(bluetoothManager: FakeBluetoothManager()))
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
    .modelContainer(for: ScanSession.self, inMemory: true)
}

#endif