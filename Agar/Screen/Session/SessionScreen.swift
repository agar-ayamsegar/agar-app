//
//  SessionScreen.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI

struct SessionScreen: View {
    @Environment(BluetoothViewModel<ElectrodeSensor>.self) var bluetoothVM
    @Environment(FreshnessViewModel.self) var freshnessVM
    @Environment(PageStateViewModel.self) var pageStateVM
    @Environment(RecapViewModel.self) var recapVM
    @Environment(\.scenePhase) private var scenePhase

    @State var sessionVM: SessionViewModel
    @State private var showSessionList = false
    // a scan the grade can't be trusted for, the user has to stab again
    @State private var scanMessage: String?
        
    var session: ScanSession
    
    init(session: ScanSession) {
        self.session = session
        self._sessionVM = State(initialValue: SessionViewModel(session: session))
    }
    
    var riwayatSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .lastTextBaseline) {
                    Text("\(sessionVM.session.totalCount)")
                        .font(.system(size: 56, weight: .bold))
                        .contentTransition(.numericText())
                    Text("Ayam")
                        .font(.title3)
                        .bold()
                }

                HStack(spacing: 8) {
                    StatCard(freshness: .fresh, value: sessionVM.session.freshCount)
                    StatCard(freshness: .notFresh, value: sessionVM.session.notFreshCount)
                }

                VStack(spacing: 0) {
                    HStack {
                        Text("Waktu").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Ayam").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Kondisi").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(sessionVM.session.records.sorted { $0.scannedAt > $1.scannedAt }) { record in
                                historyRow(record)
                                Divider()
                            }
                        }
                    }
                    .background(.white, in: .rect(cornerRadius: 12))
                }
            }
            .animation(.default, value: sessionVM.session.totalCount)
            .padding(20)
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
        .safeAreaInset(edge: .bottom) {
            Text("Tahan Untuk Akhiri Sesi")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .glassEffect(.regular, in: .capsule)
                .contentShape(.capsule)
                .onLongPressGesture(minimumDuration: 1) {
                    pageStateVM.setState(.summary(sessionVM.endSession()))
                }
                .padding(.horizontal)
                .opacity(sessionVM.canEndSession ? 1 : 0.4)
                .allowsHitTesting(sessionVM.canEndSession)
        }
    }
}


#Preview("Preparing") {
    SessionScreen(session: ScanSession(number: 1))
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
}

#Preview("Ready") {
    SessionScreen(session: ScanSession(number: 1))
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
}

#Preview("Scanning") {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
}

#Preview("Fresh") {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    let result = ScanRecord(chickenNumber: 61, freshness: .fresh)

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
}

#Preview("Next Chicken") {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
}

#Preview("Not Fresh") {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    let result = ScanRecord(chickenNumber: 61, freshness: .notFresh)

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
    .environment(PageStateViewModel())
    .environment(RecapViewModel())
}
