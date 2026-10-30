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

    init(id: UUID = UUID(), chickenNumber: Int, scannedAt: Date = .now, freshness: Freshness) {
        self.id = id
        self.chickenNumber = chickenNumber
        self.scannedAt = scannedAt
        self.freshness = freshness
    }
}
