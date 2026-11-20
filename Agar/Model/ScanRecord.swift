//
//  ScanRecord.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import Foundation
import SwiftData

@Model
final class ScanRecord: Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var chickenNumber: Int
    var scannedAt: Date
    var freshness: Freshness
    var humidity: Float
    var gas: Float
    var temperature: Float
    var session: ScanSession?

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
