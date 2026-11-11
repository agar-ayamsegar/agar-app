//
//  BluetoothViewModel.swift
//  Agar
//
//  Created by Bee Wijaya on 28/10/26.
//

import SwiftUI


enum BluetoothState: Equatable {
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

    // the pairing passkey is typed by hand, give the operator room
    private let pairingTimeout = 30
    
    init(bluetoothManager: IBluetoothManager = BluetoothManager()) {
        self.bluetoothManager = bluetoothManager
    }
    
    
    // connecting to service and running the subscribe message
    func connect() async {
        state = .scanning
        do {
            try await bluetoothManager?.connect()
            try await bluetoothManager?.readCharacteristics(onData: readData)
            try await waitForFirstReading()
            state = .connected
        } catch {
            state = .error(error.localizedDescription)
        }
    }
        
    // the pairing popup lands after the subscribe, so the machine is only really on
    // the line once it sends a row we can decode
    // ponytail: 1s poll, swap for a continuation if the first row has to land faster
    private func waitForFirstReading() async throws {
        for _ in 0..<pairingTimeout {
            if !characteristics.isEmpty { return }
            if bluetoothManager?.isConnected == false { throw BluetoothError.machineNotFound }
            try await Task.sleep(for: .seconds(1))
        }
        throw BluetoothError.noData
    }

    func readData(characteristic: String) {
        guard characteristic != "" else { return }
        
        do {
            let sensor = try getJson(value: characteristic)
            guard let sensor = sensor else { return }
            characteristics.append(sensor)
        } catch {
            print("[ble] bad packet: \(error.localizedDescription)")
        }
    }
    func clear(){
        characteristics.removeAll()
    }
    
    func getJson(value: String) throws -> T? {
        guard let v = value.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        let sensor = try decoder.decode(T.self, from: v)
        return sensor
    }
}
