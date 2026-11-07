//
//  SessionScreen.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI

struct SessionScreen: View {
    private static let baselineRows = FreshnessModel.rowsPerWindow + 7
    @Environment(BluetoothViewModel<Sensor>.self) var bluetoothVM
    @State var viewModel: SessionViewModel
    @Environment(FreshnessViewModel.self) var freshnessVM
    var onBack: () -> Void
    var onEnd: (ScanSession) -> Void

    init(viewModel: SessionViewModel, onBack: @escaping () -> Void, onEnd: @escaping (ScanSession) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onBack = onBack
        self.onEnd = onEnd
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
                .padding()
                .navigationSplitViewColumnWidth(340)
                .containerBackground(.white, for: .navigation)
                .toolbar(removing: .sidebarToggle)
                .toolbar(.hidden, for: .navigationBar)
        } detail: {
            machinePanel
                .toolbar(.hidden, for: .navigationBar)
        }
        .navigationSplitViewStyle(.balanced)
        .task(id: viewModel.attempt) {
            await prepareMachine()
        }
    }

    // the operator says the box is empty by getting here, so the baseline is taken from now on
        private func prepareMachine() async {
        // the baseline is kept for as long as the app runs, restart the iPad to take a new one
        guard freshnessVM.needsBaseline else {
            print("[session] baseline already taken")
            viewModel.machineReady()
            await readChicken()
            return
        }

        // rows from before this screen could be anything, the empty box starts counting now
        bluetoothVM.clear()
        await collectBaselineRows()
        guard !Task.isCancelled else { return }

        let rows = bluetoothVM.characteristics
        print("[session] calibrating on \(rows.count) rows")
        freshnessVM.calibrate(withEmptyBox: rows)

        if freshnessVM.needsBaseline {
            print("[session] no baseline, \(freshnessVM.state)")
            viewModel.connectionFailed()
            return
        }

        print("[session] machine ready")
        viewModel.machineReady()
        await readChicken()
    }

    // "Menyiapkan Mesin": fill the progress bar while the empty box rows come in
    private func collectBaselineRows() async {
        while bluetoothVM.characteristics.count < Self.baselineRows, !Task.isCancelled {
            let count = bluetoothVM.characteristics.count
            viewModel.preparing(progress: Double(count) / Double(Self.baselineRows))
            print("[session] preparing: \(count)/\(Self.baselineRows) rows")
            try? await Task.sleep(for: .seconds(1))
        }
    }

    // read whatever is in the box once a second and print what the model says
    private func readChicken() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))

            freshnessVM.scan(bluetoothVM.characteristics)

            if case .scanned(let freshness) = freshnessVM.state, let rel = freshnessVM.rel {
                print("[session] rel137 \(rel.rel137) rel135 \(rel.rel135) -> \(freshness.title)")
            } else {
                print("[session] \(freshnessVM.state)")
            }
        }
    }
}


#Preview("Preparing", traits: .landscapeLeft) {
    SessionScreen(
        viewModel: SessionViewModel(session: ScanSession(number: 137), machineState: .preparing(progress: 0.85)),
        onBack: {},
        onEnd: { _ in }
    )
    .environment(BluetoothViewModel<Sensor>())
    .environment(FreshnessViewModel())
}

#Preview("Ready", traits: .landscapeLeft) {
    SessionScreen(
        viewModel: SessionViewModel(session: ScanSession(number: 137), machineState: .ready),
        onBack: {},
        onEnd: { _ in }
    )
    .environment(BluetoothViewModel<Sensor>())
    .environment(FreshnessViewModel())
}

#Preview("Scanning", traits: .landscapeLeft) {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })

    SessionScreen(
        viewModel: SessionViewModel(session: session, machineState: .scanning(chickenNumber: 66, progress: 0.4)),
        onBack: {},
        onEnd: { _ in }
    )
    .environment(BluetoothViewModel<Sensor>())
    .environment(FreshnessViewModel())
}

#Preview("Fresh", traits: .landscapeLeft) {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    let result = ScanRecord(chickenNumber: 61, freshness: .fresh)

    SessionScreen(
        viewModel: SessionViewModel(session: session, machineState: .result(result)),
        onBack: {},
        onEnd: { _ in }
    )
    .environment(BluetoothViewModel<Sensor>())
    .environment(FreshnessViewModel())
}

#Preview("Next Chicken", traits: .landscapeLeft) {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })

    SessionScreen(
        viewModel: SessionViewModel(session: session, machineState: .nextChicken),
        onBack: {},
        onEnd: { _ in }
    )
    .environment(BluetoothViewModel<Sensor>())
    .environment(FreshnessViewModel())
}

#Preview("Not Fresh", traits: .landscapeLeft) {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    let result = ScanRecord(chickenNumber: 61, freshness: .notFresh)

    SessionScreen(
        viewModel: SessionViewModel(session: session, machineState: .result(result)),
        onBack: {},
        onEnd: { _ in }
    )
    .environment(BluetoothViewModel<Sensor>())
    .environment(FreshnessViewModel())
}
