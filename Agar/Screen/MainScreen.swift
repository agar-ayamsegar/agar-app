//
//  MainScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


struct MainScreen: View {
    @State var pageStateVM: PageStateViewModel = PageStateViewModel(state: .connect)
    @State var bluetoothVM: BluetoothViewModel<Sensor> = BluetoothViewModel()
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
        // design is light-only for now
        .preferredColorScheme(.light)
        // app copy is Indonesian, format dates the same way
        .environment(\.locale, Locale(identifier: "id_ID"))
    }
}


#Preview(traits: .landscapeLeft) {
    MainScreen()
}
