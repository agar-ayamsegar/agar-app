//
//  ElectrodeSensor.swift
//  Agar
//
//  Created by Bee Wijaya on 12/11/26.
//

import SwiftUI

struct ElectrodeSensor: Decodable, Sendable, Hashable {
    var ohm: Float
    var vTotal: Float
    var vChicken: Float
    var chicken: Bool
    
    private enum CodingKeys: String, CodingKey {
        case ohm = "ohm"
        case vTotal = "v_total"
        case vChicken = "v_chk"
        case chicken = "chicken"
    }
}
