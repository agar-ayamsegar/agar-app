//
//  ChickenPose.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import Foundation


// every chicken illustration, rawValue is the image set name in Assets.xcassets
enum ChickenPose: String, CaseIterable {
    case searching = "ChickenSearching"
    case preparing = "ChickenPreparing"
    case ready = "ChickenReady"
    case scanning = "ChickenScanning"
    case fresh = "ChickenFresh"
    case notFresh = "ChickenNotFresh"
}
