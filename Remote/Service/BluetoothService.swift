//
//  BluetoothService.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import Foundation
import CoreBluetooth

final class BluetoothService: NSObject {
    private lazy var centralManager = CBCentralManager(
        delegate: self,
        queue: nil,
        options: [CBCentralManagerOptionRestoreIdentifierKey: "GR"]
    )
}

extension BluetoothService {
    func scan() {
        
    }
    
    func connect(to peripheral: CBPeripheral) {
        
    }
}


extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("poweredOff")
        case .poweredOn:
            print("poweredOn")
            scan()
        case .resetting:
            print("resetting")
        case .unauthorized:
            print("unauthorized")
        case .unsupported:
            print("unsupported")
        case .unknown:
            fallthrough
        @unknown default:
            print("unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("willRestore state \(dict)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral \(peripheral) error \(error?.localizedDescription ?? "")")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("didDiscover \(peripheral) advertisementData \(advertisementData) rssi \(RSSI)")
        connect(to: peripheral)
    }
}
