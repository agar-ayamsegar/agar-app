//
//  MainScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


struct MainScreen: View {
    @State var pageStateVM: PageStateViewModel = PageStateViewModel()
    @State var bluetoothVM: BluetoothViewModel<ElectrodeSensor> = BluetoothViewModel()
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
                SessionScreen(session: session)
                .environment(bluetoothVM)
                .environment(freshnessVM)
                .environment(pageStateVM)
            case .summary(let session):
                SessionSummaryScreen(session: session) {
                    recapVM.add(session)
                    pageStateVM.setState(.home)
                }
            }
        }
        .preferredColorScheme(.light)
        .environment(\.locale, Locale(identifier: "id_ID"))
    }
}


#Preview(traits: .landscapeLeft) {
    MainScreen()
}
