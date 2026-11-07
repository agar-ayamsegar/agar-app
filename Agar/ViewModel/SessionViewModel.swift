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
    // bumped by retry, the screen restarts the warm up when this changes
    private(set) var attempt = 0

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

    func retry() {
        machineState = .preparing(progress: 0)
        attempt += 1
    }

}
