//
//  MachineState.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import Foundation

enum MachineState: Sendable, Hashable {
    case preparing(progress: Double)
    case connectionFailed
    case ready
    case scanning(chickenNumber: Int, progress: Double)
    case result(ScanRecord)
}
