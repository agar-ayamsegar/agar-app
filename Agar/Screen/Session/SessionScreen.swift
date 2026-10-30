//
//  SessionScreen.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI

struct SessionScreen: View {
    @State var viewModel: SessionViewModel
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
    }
}


#Preview("Preparing", traits: .landscapeLeft) {
    SessionScreen(
        viewModel: SessionViewModel(session: ScanSession(number: 137), machineState: .preparing(progress: 0.85)),
        onBack: {},
        onEnd: { _ in }
    )
}

#Preview("Ready", traits: .landscapeLeft) {
    SessionScreen(
        viewModel: SessionViewModel(session: ScanSession(number: 137), machineState: .ready),
        onBack: {},
        onEnd: { _ in }
    )
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
}
