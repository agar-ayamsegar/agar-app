//
//  Freshness.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI


enum Freshness: String, Sendable, Hashable, CaseIterable {
    case fresh
    case notFresh
    case unknown
    
    var title: String {
        switch self {
        case .fresh:
            return "Segar"
        case .notFresh:
            return "Tidak Segar"
        case .unknown:
            return "Tidak diketahui" // currently if model failed to initiate
        }
    }
    
    var tint: Color {
        switch self {
        case .fresh:
            return .freshGreen
        case .notFresh:
            return .notFreshRed
        case .unknown:
            return .clear
        }
    }
    
    var lightTint: Color {
        switch self {
        case .fresh:
            return .freshGreenLight
        case .notFresh:
            return .notFreshRedLight
        case .unknown:
            return .clear
        }
    }
    
    var pose: ChickenPose {
        switch self {
        case .fresh:
            return .fresh
        case .notFresh:
            return .notFresh
        case .unknown:
            return .preparing
        }
    }
    
    var instruction: String? {
        switch self {
        case .fresh, .unknown:
            return nil
        case .notFresh:
            return "Pisahkan Ayam ini !"
        }
    }
    var referenceRanges: [(label: String, range: String)] {
        [
            ("Kelembapan", "… - …"),
            ("Gas", "… - …"),
            ("Suhu", "… - …"),
        ]
    }
}
