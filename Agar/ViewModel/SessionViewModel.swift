//
//  SessionViewModel.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI


@Observable
class SessionViewModel {
    // MARK: - state variable
    private(set) var session: ScanSession
    private(set) var machineState: MachineState
    // rows of the chicken currently on the probe
    private(set) var stabRows: [ElectrodeSensor] = []
    // the chicken just judged is still stabbed, it must come off before the next scan
    private var waitingForRemoval = false

    init(session: ScanSession, machineState: MachineState = .preparing(progress: 0)) {
        self.session = session
        self.machineState = machineState
    }

    // session can only be ended once the machine is connected
    var canEndSession: Bool {
        switch machineState {
        case .preparing, .connectionFailed:
            return false
        case .ready, .scanning, .result, .nextChicken:
            return true
        }
    }

    var canRetry: Bool {
        machineState == .connectionFailed
    }


    // one row from the machine, the probe itself says when a scan starts and ends
    // returns true once the window is full and the verdict can be taken
    func collect(_ row: ElectrodeSensor) -> Bool {
        guard row.chicken else {
            // probe is empty, whoever was on it is done and a part scan is junk
            waitingForRemoval = false
            stabRows.removeAll()

            switch machineState {
            case .scanning, .result:
                machineState = session.records.isEmpty ? .ready : .nextChicken
            case .preparing, .connectionFailed, .ready, .nextChicken:
                break
            }
            return false
        }

        // the chicken we just judged has not come off yet
        guard !waitingForRemoval else { return false }

        switch machineState {
        case .preparing, .connectionFailed, .result:
            return false
        case .ready, .nextChicken, .scanning:
            break
        }

        stabRows.append(row)
        machineState = .scanning(
            chickenNumber: session.totalCount + 1,
            progress: Double(stabRows.count) / Double(FreshnessViewModel.rowsPerScan)
        )
        return stabRows.count == FreshnessViewModel.rowsPerScan
    }

    func nextChicken() {
        machineState = .nextChicken
    }

    func record(_ freshness: Freshness) {
        let record = ScanRecord(chickenNumber: session.totalCount + 1, freshness: freshness)
        session.records.append(record)
        machineState = .result(record)
        stabRows.removeAll()
        waitingForRemoval = true
    }

    func endSession() -> ScanSession {
        session.endedAt = .now
        return session
    }

    // MARK: - machine state, driven by the warm up on SessionScreen
    func preparing(progress: Double) {
        machineState = .preparing(progress: progress)
    }

    // baseline is taken, the box is ready for a chicken
    func machineReady() {
        machineState = .ready
    }

    func connectionFailed() {
        machineState = .connectionFailed
    }

    // the box is ready as soon as the esp32 is on the line, no warm up to wait for
    // ponytail: two stage bar, swap for a real count if the progress has to be honest
    func connection(_ state: BluetoothState) {
        switch state {
        case .connected:
            // a scan already running stays where it is
            guard !canEndSession else { return }
            machineState = .ready
        case .error:
            machineState = .connectionFailed
        case .idle:
            machineState = .preparing(progress: 0.2)
        case .scanning:
            machineState = .preparing(progress: 0.6)
        }
    }

}
