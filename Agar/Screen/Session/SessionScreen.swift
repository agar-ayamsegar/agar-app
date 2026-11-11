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

    @State var sessionVM: SessionViewModel
    var session: ScanSession
    
    init(session: ScanSession) {
        self.session = session
        self._sessionVM = State(initialValue: SessionViewModel(session: session))
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
        .onChange(of: bluetoothVM.state, initial: true) { _, state in
            sessionVM.connection(state)
        }
        .onChange(of: bluetoothVM.characteristics.count) {
            guard let row = bluetoothVM.characteristics.last else { return }
            print("[row] ohm \(row.ohm) chicken \(row.chicken)")

            guard sessionVM.collect(row) else { return }
            freshnessVM.scan(sessionVM.stabRows)

            if case .scanned(let freshness) = freshnessVM.state {
                sessionVM.record(freshness)
            }
        }
        .task {
            // already paired from an earlier session, nothing to prepare
            guard bluetoothVM.state != .connected else { return }
            await bluetoothVM.connect()
        }
    }
}


#Preview("Preparing", traits: .landscapeLeft) {
    SessionScreen(session: ScanSession(number: 1))
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
}

#Preview("Ready", traits: .landscapeLeft) {
    SessionScreen(session: ScanSession(number: 1))
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
}

#Preview("Scanning", traits: .landscapeLeft) {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
}

#Preview("Fresh", traits: .landscapeLeft) {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    let result = ScanRecord(chickenNumber: 61, freshness: .fresh)

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
}

#Preview("Next Chicken", traits: .landscapeLeft) {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
}

#Preview("Not Fresh", traits: .landscapeLeft) {
    let session = ScanSession(number: 137, records: (1...65).map {
        ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 30) ? .notFresh : .fresh)
    })
    let result = ScanRecord(chickenNumber: 61, freshness: .notFresh)

    SessionScreen(session: session)
    .environment(BluetoothViewModel<ElectrodeSensor>())
    .environment(FreshnessViewModel())
}
