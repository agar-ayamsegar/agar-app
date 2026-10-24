//
//  MainScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


struct MainScreen: View {
    @State var pageStateVM: PageStateViewModel = PageStateViewModel()
    
    var body: some View {
        VStack {
            switch pageStateVM.state {
            case .home:
                HomeScreen()
            }
        }
    }
}


#Preview {
    MainScreen()
}
