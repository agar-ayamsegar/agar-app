//
//  ScanSession.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import Foundation


struct ScanSession: Identifiable, Sendable, Hashable {
    let id: UUID
    let number: Int
    let startedAt: Date
    var endedAt: Date?
    var records: [ScanRecord]

    init(id: UUID = UUID(), number: Int, startedAt: Date = .now, endedAt: Date? = nil, records: [ScanRecord] = []) {
        self.id = id
        self.number = number
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.records = records
    }

    var totalCount: Int { records.count }
    var freshCount: Int { records.filter { $0.freshness == .fresh }.count }
    var notFreshCount: Int { records.filter { $0.freshness == .notFresh }.count }

    var duration: Duration { .seconds((endedAt ?? .now).timeIntervalSince(startedAt)) }
    var durationPerChicken: Duration { totalCount > 0 ? duration / totalCount : .zero }
}
