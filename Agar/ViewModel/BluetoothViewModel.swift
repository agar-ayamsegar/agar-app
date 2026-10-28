//
//  BluetoothViewModel.swift
//  Agar
//
//  Created by Bee Wijaya on 28/10/26.
//

import SwiftUI


enum BluetoothState {
    case idle,
         scanning,
         connected,
        error(String)
}

@Observable
class BluetoothViewModel {
    // MARK: - bluetooth manager coming from services
    private var bluetoothManager: BluetoothManager?
    
    
    // MARK: - state variable
    private(set) var state: BluetoothState = .idle
    private(set) var characteristics: [String] = []
    
    init(bluetoothManager: BluetoothManager = BluetoothManager()) {
        self.bluetoothManager = bluetoothManager
    }
    
    
    // connecting to service and running the subscribe message
    func connect() async {
        do {
            try await bluetoothManager?.connect()
            try await bluetoothManager?.readCharacteristics(onData: readData)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
        
    func readData(characteristic: String) {
        characteristics.append(characteristic)
    }
}
