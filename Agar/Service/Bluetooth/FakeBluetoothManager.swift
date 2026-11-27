//
//  FakeBluetoothManager.swift
//  Agar
//

#if DEBUG
import Foundation

/// Stands in for the ESP32 so a session can be walked through with no hardware on the bench.
///
/// It plays `Fake.chickenOhms` on a loop: the probe goes into a bird, holds long enough for a
/// verdict, comes out, and the next one starts. `SessionViewModel` reads nothing but the rows
/// themselves, so the script is rows rather than events, the same as what comes off the wire.
final class FakeBluetoothManager: IBluetoothManager {
    /// The firmware sends a row a second. A little quicker here so a walkthrough does not drag.
    static let rowInterval: Duration = .milliseconds(800)

    /// Long enough that the preparing panel gets seen instead of flashing past.
    static let handshake: Duration = .seconds(1.2)

    /// Rows with the probe out before each bird. `collect()` needs at least one to let go of
    /// the chicken it just judged; the rest are the operator reaching for the next one, and
    /// they are what holds the panel on "Mesin Siap Digunakan" long enough to be read.
    static let rowsBetweenChickens = 5

    /// Nothing across the pins reads about as high as an open circuit.
    static let openProbeOhm: Float = 4000

    private var feed: Task<Void, Never>?

    private(set) var isConnected = false

    func connect() async throws {
        feed?.cancel()
        feed = nil
        isConnected = false

        try await Task.sleep(for: Self.handshake)
        isConnected = true
    }

    func readCharacteristics(onData: @escaping (String) -> Void) async throws {
        guard isConnected else { throw BluetoothError.machineNotFound }

        feed?.cancel()
        feed = Task {
            let rows = Self.rows
            var index = 0

            // every session reconnects, so the script restarts at the first chicken and a
            // walkthrough reads the same way each time
            while !Task.isCancelled {
                onData(rows[index % rows.count])
                index += 1

                do {
                    try await Task.sleep(for: Self.rowInterval)
                } catch {
                    return
                }
            }
        }
    }

    /// A scripted probe is never yanked off the line, so there is nothing to report. The real
    /// manager is the one that has to care.
    func observeDisconnection(onDisconnect: @escaping () -> Void) {}

    /// The whole loop, flattened to the lines the firmware would have sent.
    ///
    /// Probe out first, then the stab. Trailing the gap instead opened the script in the
    /// middle of a bird, so the first row off a fresh connection already read `chicken`: the
    /// panel went from Menyiapkan Mesin straight to Sedang Menganalisa and Mesin Siap
    /// Digunakan was never on screen. Real hardware idles open while the operator reaches.
    private static let rows: [String] = Fake.chickenOhms.flatMap { ohm in
        Array(repeating: row(ohm: openProbeOhm, chicken: false), count: rowsBetweenChickens)
            + stab(ohm: ohm)
    }

    /// One stab: the rows the grade is taken from, plus one more because the probe stays in a
    /// moment longer than the verdict needs.
    ///
    /// The grade is the median of the scored window, so that window is built symmetric about
    /// the target and the median lands exactly on it.
    private static func stab(ohm: Float) -> [String] {
        let scored: [Float] = (0 ..< FreshnessViewModel.sampleCount).map { index in
            guard index > 0 else { return ohm }
            let step = Float((index + 1) / 2) * 1.5

            return index.isMultiple(of: 2) ? ohm - step : ohm + step
        }
        // rows FreshnessViewModel throws away before it starts scoring
        let settling = Array(repeating: ohm + 4, count: FreshnessViewModel.settleSeconds)

        return (settling + scored + [ohm + 1]).map { row(ohm: $0, chicken: true) }
    }

    private static func row(ohm: Float, chicken: Bool) -> String {
        // the divider the firmware reports, so at least the numbers hang together
        let vTotal: Float = 3.30
        let vChicken = chicken ? vTotal * ohm / (ohm + 1000) : 0

        return #"{"ohm":\#(ohm),"v_total":\#(vTotal),"v_chk":\#(vChicken),"chicken":\#(chicken)}"#
    }
}
#endif
