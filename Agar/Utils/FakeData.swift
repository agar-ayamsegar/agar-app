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
    static let enabled = false

    /// Recap history on launch. Off shows the app the way a brand new user sees it.
    static let seedsSessions = false

    /// Runs the scan screen off a scripted probe instead of the ESP32.
    static let usesFakeMachine = false
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
        /// Today's batches are placed against the clock rather than against the hour, so
        /// they are always already finished. Pinned to an hour they read as nonsense on a
        /// morning demo: the recap would open on a batch dated this afternoon that somehow
        /// already has an end time and a full record table.
        var endedMinutesAgo: Double? = nil
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
    ///
    /// A few birds in a crate failing is the ordinary day, so the rates sit at 4 to 11 per
    /// cent. The one crate that fails outright is a delivery that was already spoiled when
    /// it arrived and went back on the truck, which is why it is six birds and not sixty:
    /// nobody probes a whole pallet once the first handful come back Tidak Segar.
    private static let specs: [Spec] = [
        Spec(number: 44, dayOffset: 0, hour: 0, minute: 0, endedMinutesAgo:  25, count:  18, rejectRate: 0.06, secondsPerChicken: 44),
        Spec(number: 43, dayOffset: 0, hour: 0, minute: 0, endedMinutesAgo: 180, count:  46, rejectRate: 0.11, secondsPerChicken: 47),
        Spec(number: 42, dayOffset: 0, hour: 0, minute: 0, endedMinutesAgo: 360, count:  72, rejectRate: 0.04, secondsPerChicken: 41),
        Spec(number: 41, dayOffset: 1, hour: 15, minute: 10, count:  22, rejectRate: 0.00, secondsPerChicken: 52),
        Spec(number: 40, dayOffset: 1, hour:  6, minute: 15, count:  64, rejectRate: 0.08, secondsPerChicken: 45),
        Spec(number: 39, dayOffset: 3, hour: 11, minute: 30, count:   6, rejectRate: 1.00, secondsPerChicken: 58),
        Spec(number: 38, dayOffset: 3, hour:  5, minute: 50, count: 110, rejectRate: 0.07, secondsPerChicken: 43),
    ]

    private static func session(_ spec: Spec) -> ScanSession {
        let startedAt = start(spec)
        let records = records(spec, startedAt: startedAt)

        return ScanSession(
            id: id(for: spec.number),
            number: spec.number,
            startedAt: startedAt,
            // closed a moment after the last bird comes off the probe, rather than at a
            // count times a rate: the birds below do not arrive on a metronome either
            endedAt: (records.last?.scannedAt ?? startedAt).addingTimeInterval(spec.secondsPerChicken),
            records: records
        )
    }

    private static func records(_ spec: Spec, startedAt: Date) -> [ScanRecord] {
        // seeded on the session number, so the recap reads the same on every launch
        var roll = Roll(seed: UInt64(spec.number))

        // the first bird is stabbed after the probe is set up, not the instant the session
        // opens, and every one after that takes its own time
        var scannedAt = startedAt

        return (1 ... spec.count).map { number in
            let freshness: Freshness = roll.unit() < spec.rejectRate ? .notFresh : .fresh
            // nobody works to the second: 0.7 to 1.3 of the nominal rate, so the Waktu
            // column reads like a shift instead of a timer
            scannedAt.addTimeInterval(spec.secondsPerChicken * (0.7 + roll.unit() * 0.6))

            return ScanRecord(
                chickenNumber: number,
                scannedAt: scannedAt,
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

    private static func start(_ spec: Spec) -> Date {
        // today's batches are anchored to the clock, so they have always already happened
        if let endedMinutesAgo = spec.endedMinutesAgo {
            let ran = Double(spec.count) * spec.secondsPerChicken

            return Date.now.addingTimeInterval(-endedMinutesAgo * 60 - ran)
        }

        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -spec.dayOffset, to: .now) ?? .now

        return calendar.date(bySettingHour: spec.hour, minute: spec.minute, second: 0, of: day) ?? day
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
    /// A crate, not a test fixture. Most birds come back Segar at a spread of readings, the
    /// way a delivery that passed actually looks, and the three that fail are scattered
    /// through it rather than lined up: one grey zone, one grade 2, one properly spoiled.
    /// Four in nineteen is still a worse crate than most, but a loop that is all Segar
    /// never shows the operator what a reject looks like.
    ///
    /// Every branch the scan screen has is still in here, including the one reading over
    /// `maxTrustedOhm` that brings up "Coba Tusuk Lagi". The bands live in
    /// `FreshnessViewModel`, so these have to move if the grading does.
    static let chickenOhms: [Float] = [
        750,  // grade 4, Segar, "Masih Layak"
        630,  // grade 2
        750,  // grade 3, Segar, "Layak"
        641,  // grey zone 2.5, Tidak Segar, "Masih Bisa Diolah"
        697,  // grade 4
        674,  // grade 4, just over the line
        713,  // grade 4
        627,  // grade 2, Tidak Segar, "Pisahkan Ayam ini !"
        683,  // grade 4
        651,  // grade 3
        913,  // over maxTrustedOhm, the bird is still cold or the skin dried out
        694,  // grade 4, the same bird stabbed again
        666,  // grade 3
        707,  // grade 4
        649,  // grade 3
        604,  // grade 1, Tidak Segar
        679,  // grade 4
        692,  // grade 4
        663,  // grade 3
    ]
}
