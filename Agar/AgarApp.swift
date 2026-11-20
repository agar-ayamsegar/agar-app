//
//  AgarApp.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI
import SwiftData

@main
struct AgarApp: App {
    var body: some Scene {
        WindowGroup {
            MainScreen()
        }
        .modelContainer(for: [ScanSession.self, ScanRecord.self])
    }
}
