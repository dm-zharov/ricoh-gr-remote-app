//
//  CameraInfo.swift
//  Remote
//
//  Created by Dmitriy Zharov on 18.07.2023.
//

import Foundation

struct CameraInfo {
    var version: String? // 9.5.2
    var modelNumber: String? // MNP13ZP/A
    var serialNumber: String? // L(67...
    var bluetooth: String? // 09:03
}

struct BatteryLevel {
    enum PowerSource: Int {
        case battery = 0
        case ac = 1
    }
    
    var batteryLevel: Int
    var powerSource: PowerSource
}
