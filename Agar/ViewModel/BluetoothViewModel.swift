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


protocol IBluetoothViewModel {
    associatedtype T: Decodable
    
    func connect() async
    func readData(characteristic: String)
    func getJson(value: String) throws -> T?
}

@Observable
class BluetoothViewModel<T: Decodable> {
    // MARK: - bluetooth manager coming from services
    private var bluetoothManager: IBluetoothManager?
    
    
    // MARK: - state variable
    private(set) var state: BluetoothState = .idle
    private(set) var characteristics: [T] = []
    
    init(bluetoothManager: IBluetoothManager = BluetoothManager()) {
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
        guard characteristic != "" else { return }
        
        do {
            let sensor = try getJson(value: characteristic)
            guard let sensor = sensor else { return }
            characteristics.append(sensor)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func getJson(value: String) throws -> T? {
        guard let v = value.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        let sensor = try decoder.decode(T.self, from: v)
        return sensor
    }
}
