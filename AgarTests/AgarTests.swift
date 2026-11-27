//
//  AgarTests.swift
//  AgarTests
//
//  Created by Bee Wijaya on 24/10/26.
//

import Testing
@testable import Agar

struct AgarTests {

    /// The scripted machine has to idle with the probe out, the way the real one does while
    /// the operator reaches for a bird. Opening the script mid stab sent the panel from
    /// Menyiapkan Mesin to Sedang Menganalisa without ever showing Mesin Siap Digunakan.
    @Test func fakeMachineOpensWithTheProbeOut() async throws {
        let machine = FakeBluetoothManager()
        try await machine.connect()

        var rows: [String] = []
        try await machine.readCharacteristics { rows.append($0) }
        try await Task.sleep(for: FakeBluetoothManager.rowInterval)

        let first = try #require(rows.first)
        #expect(first.contains(#""chicken":false"#))
    }

}
