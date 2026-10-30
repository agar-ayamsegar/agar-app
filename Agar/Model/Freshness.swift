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
    
    var title: String {
        switch self {
        case .fresh:
            return "Segar"
        case .notFresh:
            return "Tidak Segar"
        }
    }
    
    var tint: Color {
        switch self {
        case .fresh:
            return .freshGreen
        case .notFresh:
            return .notFreshRed
        }
    }
    
    var lightTint: Color {
        switch self {
        case .fresh:
            return .freshGreenLight
        case .notFresh:
            return .notFreshRedLight
        }
    }
    
    var pose: ChickenPose {
        switch self {
        case .fresh:
            return .fresh
        case .notFresh:
            return .notFresh
        }
    }
    
    var instruction: String? {
        switch self {
        case .fresh:
            return nil
        case .notFresh:
            return "Pisahkan Ayam ini !"
        }
    }
}
