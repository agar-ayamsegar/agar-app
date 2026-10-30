//
//  Sensor.swift
//  Agar
//
//  Created by Bee Wijaya on 28/10/26.
//

import Foundation


struct Sensor: Decodable, Sendable, Hashable {
    var mq137: Float
    var mq135: Float
    var rs137: Float
    var rs135: Float
    var rel137: Float
    var rel135: Float
    var temp: Float
    var humidity: Float
    
    private enum CodingKeys: String, CodingKey {
        case mq137 = "mq_137"
        case mq135 = "mq_135"
        case rs137 = "rs_137"
        case rs135 = "rs_135"
        case temp = "temp"
        case humidity = "humidity"
        case rel137 = "rel_137"
        case rel135 = "rel_135"
    }
}
