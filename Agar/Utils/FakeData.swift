//
//  FakeData.swift
//  Agar
//
//  Created by Bee Wijaya on 04/11/26.
//

import SwiftUI

enum Fake {
    // rs is what the model reads, in kOhm, same as the firmware sends. raw counts (0-4095)
    // are only here so the railed-sensor case can be faked.
    static func rows(count: Int, mq137: Float, mq135: Float,
                     rs137: Float, rs135: Float, wobble: Float = 1) -> [Sensor] {
        let pattern: [Float] = [0, 1, -1, 1, 0, -1, 1, -1, 0, 1]

        return (0 ..< count).map { index in
            let nudge = pattern[index % pattern.count] * wobble
            return Sensor(mq137: mq137 + nudge, mq135: mq135 + nudge,
                          rs137: rs137 * (1 + nudge / 100), rs135: rs135 * (1 + nudge / 100),
                          rel137: 0, rel135: 0,
                          temp: 34, humidity: 60)
        }
    }

    // the clean box every fake chicken below is measured against
    static let airRs137: Float = 12.0
    static let airRs135: Float = 20.0

    static let emptyBox = rows(count: 120, mq137: 525, mq135: 640, rs137: airRs137, rs135: airRs135)
}


enum FakeChicken: String, CaseIterable, Identifiable {
    case fresh       = "Segar"
    case rotten      = "Busuk"
    case borderline  = "Batas"
    case looseGround = "GND Lepas"
    case tooShort    = "Kurang Data"

    var id: String { rawValue }

    var rows: [Sensor] {
        switch self {
        // rel = rs / Fake.airRs: fresh sits near 0.76, unfresh near 0.21, split at 0.45
        case .fresh:
            return Fake.rows(count: 60, mq137: 600, mq135: 770,
                             rs137: Fake.airRs137 * 0.80, rs135: Fake.airRs135 * 0.76)
        case .rotten:
            return Fake.rows(count: 60, mq137: 956, mq135: 2590,
                             rs137: Fake.airRs137 * 0.30, rs135: Fake.airRs135 * 0.21)
        case .borderline:
            // sits exactly where the model changes its mind, wobbling +/- 9
            return Fake.rows(count: 60, mq137: 800, mq135: 1156,
                             rs137: Fake.airRs137 * 0.50, rs135: Fake.airRs135 * 0.45, wobble: 9)
        case .looseGround:
            return Fake.rows(count: 60, mq137: 956, mq135: FreshnessModel.adcMax,
                             rs137: Fake.airRs137 * 0.30, rs135: 0.01)
        case .tooShort:
            return Fake.rows(count: 3, mq137: 956, mq135: 2590,
                             rs137: Fake.airRs137 * 0.30, rs135: Fake.airRs135 * 0.21)
        }
    }
}


enum Source: String, CaseIterable, Identifiable {
    case dummy = "Data Palsu"
    case esp32 = "ESP32"

    var id: String { rawValue }
}
