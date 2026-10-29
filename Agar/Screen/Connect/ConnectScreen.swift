//
//  ConnectScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 27/10/26.
//

import SwiftUI


struct ConnectScreen: View {
    @Environment(BluetoothViewModel<Sensor>.self) var bluetoothVM
    
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
                Text("mq_137: \(data.mq137), mq_135: \(data.mq135), rs_137: \(data.rs137), rs_135: \(data.rs135), temp: \(data.temp), humidity: \(data.humidity)")
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
        .environment(BluetoothViewModel<Sensor>())
}
