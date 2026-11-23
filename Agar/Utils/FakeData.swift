//
//  FakeData.swift
//  Agar
//
//  Created by Bee Wijaya on 04/11/26.
//

import Foundation
import SwiftData

/// Sample data, so the app can be shown and walked through without the ESP32 on the bench.
///
/// The switches below only do anything in a Debug build. A release build starts with an
/// empty recap and always talks to the real machine, whatever they are set to here.
enum Fake {
    /// The master switch. Turn this off and the app behaves as though this file were not
    /// here: empty recap, real ESP32. The two below only do anything while it is on.
    static let enabled = true

    /// Recap history on launch. Off shows the app the way a brand new user sees it.
    static let seedsSessions = true

    /// Runs the scan screen off a scripted probe instead of the ESP32.
    static let usesFakeMachine = true
}


// MARK: - recap history

extension Fake {
    /// The machine `MainScreen` talks to: the real one unless this is a Debug build with
    /// the fake switched on.
    static var machine: IBluetoothManager {
        #if DEBUG
        return enabled && usesFakeMachine ? FakeBluetoothManager() : BluetoothManager()
        #else
        return BluetoothManager()
        #endif
    }

    /// Puts the sample sessions in the store, replacing the ones from the last launch.
    ///
    /// They are dated against today, so rebuilding beats leaving them to drift into last
    /// week and the recap opening empty. Only the fixed ids below are cleared out, so a
    /// session actually recorded on the device is never touched.
    static func seedSessions(into context: ModelContext) {
        #if DEBUG
        // cleared whichever way the switch is set: turning it off has to take the sample
        // sessions with it, or they sit in the store looking like ones somebody recorded
        let sampleIDs = Set(specs.map { id(for: $0.number) })
        let stored = (try? context.fetch(FetchDescriptor<ScanSession>())) ?? []

        for session in stored where sampleIDs.contains(session.id) {
            context.delete(session)
        }
        // saved before the inserts land, or the ids going back in collide with the old rows
        try? context.save()

        guard enabled, seedsSessions else { return }

        for spec in specs {
            context.insert(session(spec))
        }
        try? context.save()
        #endif
    }

    private struct Spec {
        let number: Int
        /// 0 is today. The recap opens on today, so something has to land there or the
        /// first thing anyone sees is still the empty state.
        let dayOffset: Int
        let hour: Int
        let minute: Int
        let count: Int
        /// Share of the batch that comes out Tidak Segar.
        let rejectRate: Double
        /// Stab, read, swap the bird. Sets how long the session ran.
        let secondsPerChicken: Double
    }

    /// Spread on purpose rather than seven identical batches: three sessions today so the
    /// list has something to choose between, a gap at two days ago so the date picker can
    /// land on "tidak ada sesi", one batch all Segar and one all Tidak Segar so both ends
    /// of the record filter can be seen empty, and one long enough that the duration shows
    /// hours and the record table actually has to scroll.
    private static let specs: [Spec] = [
        Spec(number: 44, dayOffset: 0, hour: 14, minute: 30, count:  8, rejectRate: 0.00, secondsPerChicken: 40),
        Spec(number: 43, dayOffset: 0, hour: 11, minute:  0, count: 24, rejectRate: 0.33, secondsPerChicken: 55),
        Spec(number: 42, dayOffset: 0, hour:  8, minute: 15, count: 60, rejectRate: 0.12, secondsPerChicken: 48),
        Spec(number: 41, dayOffset: 1, hour: 16, minute:  5, count: 18, rejectRate: 0.17, secondsPerChicken: 50),
        Spec(number: 40, dayOffset: 1, hour:  9, minute: 40, count: 36, rejectRate: 0.08, secondsPerChicken: 45),
        Spec(number: 39, dayOffset: 3, hour: 13, minute: 20, count: 12, rejectRate: 1.00, secondsPerChicken: 60),
        Spec(number: 38, dayOffset: 3, hour:  7, minute: 50, count: 95, rejectRate: 0.15, secondsPerChicken: 42),
    ]

    private static func session(_ spec: Spec) -> ScanSession {
        let startedAt = start(dayOffset: spec.dayOffset, hour: spec.hour, minute: spec.minute)

        return ScanSession(
            id: id(for: spec.number),
            number: spec.number,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(Double(spec.count) * spec.secondsPerChicken),
            records: records(spec, startedAt: startedAt)
        )
    }

    private static func records(_ spec: Spec, startedAt: Date) -> [ScanRecord] {
        // seeded on the session number, so the recap reads the same on every launch
        var roll = Roll(seed: UInt64(spec.number))

        return (1 ... spec.count).map { number in
            let freshness: Freshness = roll.unit() < spec.rejectRate ? .notFresh : .fresh

            return ScanRecord(
                chickenNumber: number,
                scannedAt: startedAt.addingTimeInterval(Double(number - 1) * spec.secondsPerChicken),
                freshness: freshness,
                humidity: 74 + Float(roll.unit() * 12),
                // a bird that failed gassed off more, that is the whole reason it failed
                gas: freshness == .notFresh ? 24 + Float(roll.unit() * 14) : 8 + Float(roll.unit() * 9),
                temperature: 26 + Float(roll.unit() * 3)
            )
        }
    }

    /// Fixed, so a relaunch replaces the same rows instead of piling up copies of them.
    /// "FA4E" is only a marker that this file invented the row.
    private static func id(for number: Int) -> UUID {
        let digits = String(number)
        let tail = String(repeating: "0", count: 12 - digits.count) + digits

        return UUID(uuidString: "FA4E0000-0000-4000-8000-\(tail)") ?? UUID()
    }

    private static func start(dayOffset: Int, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    /// A fixed "every fourth chicken" pattern reads like a test fixture rather than a
    /// shift, but the recap still has to look the same every launch. Small xorshift.
    private struct Roll {
        private var state: UInt64

        init(seed: UInt64) { state = seed | 1 }

        /// 0 up to 1.
        mutating func unit() -> Double {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17

            return Double(state % 10_000) / 10_000
        }
    }
}


// MARK: - scripted probe

extension Fake {
    /// What the fake probe reads, one entry per chicken, looping.
    ///
    /// Picked to walk every branch the scan screen has rather than to look plausible: both
    /// Segar grades, the grey zone, both Tidak Segar grades, and one reading over
    /// `maxTrustedOhm` so the "Coba Tusuk Lagi" alert turns up too. The bands live in
    /// `FreshnessViewModel`, so these have to move if the grading does.
    static let chickenOhms: [Float] = [
        700,  // grade 4, Segar, "Masih Layak"
        655,  // grade 3, Segar, "Layak"
        620,  // grade 2, Tidak Segar
        640,  // grey zone 2.5, Tidak Segar, "Masih Bisa Diolah"
        880,  // over maxTrustedOhm: scan is thrown away and another stab is asked for
        598,  // grade 1, Tidak Segar
    ]
}
