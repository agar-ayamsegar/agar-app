//
//  FreshnessViewModel.swift
//  Agar
//
//  Created by Bee Wijaya on 04/11/26.
//

import SwiftUI

enum FreshnessState {
    case idle,
         scanned(Freshness),
         error(String)
}

@Observable
class FreshnessViewModel {
    // nothing is thrown away, every row of the stab counts
    static let settleSeconds = 0
    // one row per second, so a 5 second stab
    static let sampleCount = 5
    // ponytail: random stab line, recalibrate against fresh meat before shipping
    static let freshOhm: Float = 942

    // how many rows a scan needs before it can decide
    static var rowsPerScan: Int { settleSeconds + sampleCount }

    // MARK: - state
    private(set) var state: FreshnessState = .idle
    private(set) var ohm: Float?

    // the median ignores a reading that jumps when a pin moves, the average would not,
    // and the thresholds were calculated on the median
    func scan(_ readings: [ElectrodeSensor]) {
        let window = readings.dropFirst(Self.settleSeconds).prefix(Self.sampleCount)

        guard window.count == Self.sampleCount else {
            state = .error("Data belum cukup")
            return
        }

        let ohm = Self.median(window.map(\.ohm))
        let freshness: Freshness = ohm >= Self.freshOhm ? .fresh : .notFresh
        self.ohm = ohm
        state = .scanned(freshness)
        print("[scan] median \(ohm) ohm -> \(freshness)")
    }

    static func median(_ values: [Float]) -> Float {
        let sorted = values.sorted()
        let mid = sorted.count / 2
        // an even count has no middle value, take the two it sits between
        return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    func reset() {
        ohm = nil
        state = .idle
    }
}
