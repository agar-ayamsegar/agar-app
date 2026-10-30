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

    init(session: ScanSession, machineState: MachineState = .preparing(progress: 0)) {
        self.session = session
        self.machineState = machineState
    }

    // session can only be ended once the machine is connected
    var canEndSession: Bool {
        switch machineState {
        case .preparing, .connectionFailed:
            return false
        case .ready, .scanning, .result:
            return true
        }
    }

    var canRetry: Bool {
        machineState == .connectionFailed
    }

    // TODO: hook into BluetoothViewModel to reconnect
    func retry() {
        machineState = .preparing(progress: 0)
    }
}
