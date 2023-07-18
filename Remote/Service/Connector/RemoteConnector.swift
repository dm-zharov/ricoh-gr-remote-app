//
//  RemoteConnector.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import Foundation

protocol RemoteConnector {
    var isReady: Bool { get }
}

extension BKPeripheral: RemoteConnector {
    var isReady: Bool {
        peripheral?.state == .connected
    }
}
