//
//  ConnectScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 27/10/26.
//


import SwiftUI


struct ConnectScreen: View {
    @Environment(BluetoothViewModel<Sensor>.self) var bluetoothVM

    // only the newest rows, the stream can get long
    private var lastRows: [(offset: Int, element: Sensor)] {
        Array(bluetoothVM.characteristics.enumerated().suffix(10))
    }

    var body: some View {
        VStack(spacing: 16) {
            AppButton(label: "Connect", style: .secondary) {
                Task {
                    await bluetoothVM.connect()
                }
            }

            Text("\(bluetoothVM.characteristics.count) baris masuk")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(lastRows, id: \.offset) { row in
                Text(String(format: "%3d  mq137 %.0f  mq135 %.0f  %.0fC  %.0f%%",
                            row.offset,
                            row.element.mq137,
                            row.element.mq135,
                            row.element.temp,
                            row.element.humidity))
                    .font(.caption)
                    .monospaced()
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    ConnectScreen()
        .environment(BluetoothViewModel<Sensor>())
}
