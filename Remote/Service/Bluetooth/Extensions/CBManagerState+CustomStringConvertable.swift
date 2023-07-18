//
//  CBManagerState+CustomStringConvertable.swift
//  Remote
//
//  Created by Dmitriy Zharov on 18.07.2023.
//

import CoreBluetooth

extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .poweredOn:
            return "poweredOn"
        case .poweredOff:
            return "poweredOff"
        case .resetting:
            return "resetting"
        case .unauthorized:
            return "unauthorized"
        case .unsupported:
            return "unsupported"
        case .unknown:
            fallthrough
        @unknown default:
            return "unknown"
        }
    }
}
