//
//  MainScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI
import SwiftData

struct MainScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanSession.number, order: .reverse) private var sessionsByNumber: [ScanSession]
    @State var pageStateVM: PageStateViewModel = PageStateViewModel()
    @State var bluetoothVM: BluetoothViewModel<ElectrodeSensor> = BluetoothViewModel()
    @State var freshnessVM: FreshnessViewModel = FreshnessViewModel()
    @State var recapVM: RecapViewModel = RecapViewModel()

    var body: some View {
        NavigationStack{
            VStack {
                switch pageStateVM.state {
                case .home:
                    HomeScreen(viewModel: recapVM) {
                        let next = (sessionsByNumber.first?.number ?? 0) + 1
                        pageStateVM.setState(.session(ScanSession(number: next)))
                    }
                case .session(let session):
                    SessionScreen(session: session)
                        .environment(bluetoothVM)
                        .environment(freshnessVM)
                        .environment(pageStateVM)
                        .environment(recapVM)
                case .summary(let session):
                    SessionSummaryScreen(session: session) {
                        modelContext.insert(session)
                        recapVM.selectedDate = session.startedAt
                        recapVM.selectedSessionID = session.id
                        recapVM.recordFilter = nil
                        pageStateVM.setState(.home)
                    }
                }
            }
            .preferredColorScheme(.light)
            .environment(\.locale, Locale(identifier: "id_ID"))
            .containerBackground(.surfaceCream, for: .navigation)
        }
    }
}


#Preview {
    MainScreen()
        .modelContainer(for: ScanSession.self, inMemory: true)
}

