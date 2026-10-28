//
//  ConnectScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 27/10/26.
//

import SwiftUI


struct ConnectScreen: View {
    @Environment(BluetoothViewModel.self) var bluetoothVM
    
    var body: some View {
        VStack {
            Text("Connect your bluetooth")
                .font(.body)
                .bold()
                .padding()
            
            AppButton(label: "Connect") {
                Task {
                    await bluetoothVM.connect()
                }
            }
            
            ForEach(bluetoothVM.characteristics.suffix(10), id: \.self) { data in
                Text(data)
                    .font(.body)
                    .bold()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    ConnectScreen()
        .environment(BluetoothViewModel())
}
