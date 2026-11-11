//
//  BluetoothManager.swift
//  Agar
//
//  Created by Bee Wijaya on 27/10/26.
//

import AsyncBluetooth
import CoreBluetooth
import Combine


enum BluetoothError: LocalizedError {
    case unavailable, machineNotFound, noData

    var errorDescription: String? {
        switch self {
        case .unavailable: "Bluetooth tidak tersedia"
        case .machineNotFound: "Mesin tidak ditemukan"
        case .noData: "Mesin tidak mengirim data"
        }
    }
}


protocol IBluetoothManager {
    var isConnected: Bool { get }

    func connect() async throws
    func readCharacteristics(onData: @escaping (String) -> Void) async throws
}


class BluetoothManager: IBluetoothManager {
    var centralManager: CentralManager?
    var peripheral: Peripheral?
    
    // constant
    let serviceId = CBUUID(string: "73332f45-02d1-46ff-a88d-edba7bfc0dc2") // value from the ESP32
    let characteristicId = CBUUID(string: "3112abef-cfd7-4bb2-b1fc-ab83c5e3f3d6") // value from ESP32
    let scanTimeout = Duration.seconds(15) // how long we look for the esp32 before giving up
    var cancellables = Set<AnyCancellable>()

    // rejecting the passkey drops the link, the peripheral tells us straight away
    var isConnected: Bool { peripheral?.state == .connected }
        
    init(centralManager: CentralManager? = CentralManager()) {
        self.centralManager = centralManager
    }
    
    // connect to the peripheral / esp32
    func connect() async throws {
        guard let centralManager = centralManager else { throw BluetoothError.unavailable }
        try await centralManager.waitUntilReady()

        // a connected esp32 stops advertising, so let go of it or the rescan finds nothing
        if let peripheral = peripheral {
            try? await centralManager.cancelPeripheralConnection(peripheral)
        }
        peripheral = nil
        
        // scanForPeripherals will scanning the latest of exist peripehral
        // we provide the serviceID that unique
        let streams = try await centralManager.scanForPeripherals(withServices: [serviceId])

        // the stream never ends by itself, so a missing machine would wait forever
        let timeout = Task {
            try await Task.sleep(for: scanTimeout)
            await centralManager.stopScan()
        }

        for await ds in streams {
            // need to loop through stream to get the peripheral
            peripheral = ds.peripheral
            break
        }

        timeout.cancel()
        await centralManager.stopScan()

        // no esp32 on the line is a failure, not a quiet success
        guard let peripheral = peripheral else { throw BluetoothError.machineNotFound }
        try await centralManager.connect(peripheral)
        guard peripheral.state == .connected else { throw BluetoothError.machineNotFound }
    }
    
    // readCharacteristics will get the message from peripheral
    // characteristicID and serviceID from ESP32 specified on the BLE
    func readCharacteristics(onData: @escaping (String) -> Void) async throws  {
        guard let peripheral = peripheral else { throw BluetoothError.machineNotFound }

        // a retry subscribes again, drop the sink from the attempt before it
        cancellables.removeAll()

        peripheral.characteristicValueUpdatedPublisher
            .filter { [weak self] in $0.characteristic.uuid == self?.characteristicId }
            .compactMap { try? $0.parsedValue() as String? }
            .sink { value in
                onData(value)
            }
            .store(in: &cancellables)
        
        try await peripheral.setNotifyValue(
            true,
            forCharacteristicWithCBUUID: characteristicId,
            ofServiceWithCBUUID: serviceId
        )
    }
}
