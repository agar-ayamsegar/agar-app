//
//  ScanRecord.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import Foundation

struct ScanRecord: Identifiable, Sendable, Hashable {
    let id: UUID
    let chickenNumber: Int
    let scannedAt: Date
    let freshness: Freshness
    let humidity: Float    
    let gas: Float         
    let temperature: Float 

    init(
        id: UUID = UUID(),
        chickenNumber: Int,
        scannedAt: Date = .now,
        freshness: Freshness,
        humidity: Float = 0,
        gas: Float = 0,
        temperature: Float = 0
    ) {
        self.id = id
        self.chickenNumber = chickenNumber
        self.scannedAt = scannedAt
        self.freshness = freshness
        self.humidity = humidity
        self.gas = gas
        self.temperature = temperature
    }
}
