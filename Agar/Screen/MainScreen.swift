//
//  MainScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


struct MainScreen: View {
    @State var pageStateVM: PageStateViewModel = PageStateViewModel()
    @State var bluetoothVM: BluetoothViewModel<Sensor> = BluetoothViewModel()
    @State var freshnessVM: FreshnessViewModel = FreshnessViewModel()
    @State var recapVM: RecapViewModel = RecapViewModel()

    var body: some View {
        VStack {
            switch pageStateVM.state {
            case .home:
                HomeScreen(viewModel: recapVM) {
                    pageStateVM.setState(.session(recapVM.makeSession()))
                }
            case .session(let session):
                SessionScreen(viewModel: SessionViewModel(session: session)) {
                    pageStateVM.setState(.home)
                } onEnd: { finishedSession in
                    pageStateVM.setState(.summary(finishedSession))
                }
                .environment(bluetoothVM)
                .environment(freshnessVM)
            case .summary(let session):
                SessionSummaryScreen(session: session) {
                    recapVM.add(session)
                    pageStateVM.setState(.home)
                }
            case .connect:
                ConnectScreen()
                    .environment(bluetoothVM)
            }
        }
        // connect as soon as the app opens, the sensors warm up while the operator is still on home
        .task {
            await bluetoothVM.connect()
            print("[main] bluetooth \(bluetoothVM.state)")
        }
        .preferredColorScheme(.light)
        .environment(\.locale, Locale(identifier: "id_ID"))
    }
}


#Preview(traits: .landscapeLeft) {
    MainScreen()
}
