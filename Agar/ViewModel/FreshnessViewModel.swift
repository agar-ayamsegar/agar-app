//
//  FreshnessViewModel.swift
//  Agar
//
//  Created by Bee Wijaya on 04/11/26.
//

import SwiftUI

// whole chicken grade, 5 (just slaughtered) is never reached from a supermarket
enum FreshnessGrade: CaseIterable, Sendable {
    // borderline is the 2.5 grey zone: not fresh any more, but it may still be cooked
    case one, two, borderline, three, four

    var number: Double {
        switch self {
        case .one: 1
        case .two: 2
        case .borderline: 2.5
        case .three: 3
        case .four: 4
        }
    }

    var label: String {
        switch self {
        case .four: "Masih Layak"
        case .three: "Layak"
        case .borderline: "Masih Bisa Diolah"
        case .two: "Tidak Layak"
        case .one: "Tidak Layak"
        }
    }

    var detail: String {
        switch self {
        case .four: "Bisa langsung diolah atau simpan di dalam freezer"
        case .three: "Masak hari ini, jangan disimpan lagi"
        case .borderline: "Masak sekarang sampai matang sempurna. Kalau bau busuk atau berlendir, jangan dipakai"
        case .two: "Kondisi daging sudah tidak layak untuk diolah atau disimpan"
        case .one: "Kondisi daging sudah tidak layak untuk diolah atau disimpan"
        }
    }

    // the screen still has two colours, grade 3 and 4 count as fresh
    var freshness: Freshness {
        switch self {
        case .three, .four: .fresh
        case .one, .two, .borderline: .notFresh
        }
    }
}

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
    // whole chicken (Hokky, 1 kg), middle of the breast, moist meat, room temperature
    // the lowest median each grade still reaches
    // ponytail: from one chicken (W01), recheck after W02 and W03
    static let gradeFourOhm: Float = 670
    static let gradeThreeOhm: Float = 646
    // 636 to 645 is the grey zone between 2 and 3, Tidak Segar but it may still be cooked
    static let greyZoneOhm: Float = 636
    static let gradeTwoOhm: Float = 610
    // above this the meat is still cold or the skin dried out, a grade would be a guess
    static let maxTrustedOhm: Float = 850

    // how many rows a scan needs before it can decide
    static var rowsPerScan: Int { settleSeconds + sampleCount }

    // MARK: - state
    private(set) var state: FreshnessState = .scanned(.fresh)
    private(set) var ohm: Float?
    private(set) var grade: FreshnessGrade?
    // 1.0 to 4.5 in half steps, for the slider
    private(set) var score: Double?
    
    // MARK: - service
    let audioManager = AudioManager()

    // the median ignores a reading that jumps when a pin moves, the average would not,
    // and the thresholds were calculated on the median
    func scan(_ readings: [ElectrodeSensor]) {
        let window = readings.dropFirst(Self.settleSeconds).prefix(Self.sampleCount)

        guard window.count == Self.sampleCount else {
            state = .error("Data belum cukup")
            return
        }

        let ohm = Self.median(window.map(\.ohm))
        self.ohm = ohm

        guard ohm <= Self.maxTrustedOhm else {
            grade = nil
            score = nil
            state = .error("Ayam masih dingin atau kulitnya kering. Cabut, lalu tusuk bagian daging yang lembap.")
            print("[scan] median \(ohm) ohm -> too high, retry")
            return
        }
        
        let grade = Self.grade(for: ohm)
        self.grade = grade
        Task.detached { await self.audioManager.playSound(grade.number < 3 ? "NotFresh" : "Fresh") }
        score = Self.score(for: ohm)
        state = .scanned(grade.freshness)
        print("[scan] median \(ohm) ohm -> grade \(grade.number) \(grade.freshness)")
    }

    static func grade(for ohm: Float) -> FreshnessGrade {
        if ohm >= gradeFourOhm { return .four }
        if ohm >= gradeThreeOhm { return .three }
        if ohm >= greyZoneOhm { return .borderline }
        if ohm >= gradeTwoOhm { return .two }
        return .one
    }

    // where the dot sits on the 1 to 5 slider
    // below 610 sits on 1, 610 to 635 slides 1.5 to 2, 636 to 645 sits on 2.5,
    // then it slides 3 to 3.5 up to 670 (green never shows 2.5) and 3.5 to 4.5 up to 800, 5 is just slaughtered
    static func score(for ohm: Float) -> Double {
        if ohm < gradeTwoOhm { return 1.0 }
        if ohm < greyZoneOhm { return slide(ohm, from: gradeTwoOhm, to: greyZoneOhm, scores: 1.5, 2.0) }
        if ohm < gradeThreeOhm { return 2.5 }
        if ohm < gradeFourOhm { return slide(ohm, from: gradeThreeOhm, to: gradeFourOhm, scores: 3.0, 3.5) }
        return slide(ohm, from: gradeFourOhm, to: maxTrustedOhm, scores: 3.5, 4.5)
    }

    private static func slide(_ ohm: Float, from low: Float, to high: Float, scores start: Double, _ end: Double) -> Double {
        let t = Double(min(max((ohm - low) / (high - low), 0), 1))
        let score = start + t * (end - start)
        // snap to half steps so the dot always sits on a number or exactly between two
        return (score * 2).rounded() / 2
    }

    static func median(_ values: [Float]) -> Float {
        let sorted = values.sorted()
        let mid = sorted.count / 2
        // an even count has no middle value, take the two it sits between
        return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    func reset() {
        ohm = nil
        grade = nil
        score = nil
        state = .idle
    }
}
