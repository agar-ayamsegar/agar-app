//
//  BluetoothManager.swift
//  Agar
//
//  Created by Bee Wijaya on 27/10/26.
//

import AsyncBluetooth
import CoreBluetooth
import Combine

class BluetoothManager {
    var centralManager: CentralManager?
    var peripheral: Peripheral?
    
    // constant
    let serviceId = CBUUID(string: "73332f45-02d1-46ff-a88d-edba7bfc0dc2") // value from the ESP32
    let characteristicId = CBUUID(string: "3112abef-cfd7-4bb2-b1fc-ab83c5e3f3d6") // value from ESP32
    var cancellables = Set<AnyCancellable>()
        
    init(centralManager: CentralManager? = CentralManager()) {
        self.centralManager = centralManager
    }
    
    // connect to the peripheral / esp32
    func connect() async throws {
        guard let centralManager = centralManager else { return }
        try await centralManager.waitUntilReady()
        
        // scanForPeripherals will scanning the latest of exist peripehral
        // we provide the serviceID that unique
        let streams = try await centralManager.scanForPeripherals(withServices: [serviceId])
        for await ds in streams {
            // need to loop through stream to get the peripheral
            peripheral = ds.peripheral
            break
        }
        
        guard let peripheral = peripheral else { return }
        
        try await centralManager.connect(peripheral)
    }
    
    // readCharacteristics will get the message from peripheral
    // characteristicID and serviceID from ESP32 specified on the BLE
    func readCharacteristics(onData: @escaping (String) -> Void) async throws  {
        guard let peripheral = peripheral else { return }

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
