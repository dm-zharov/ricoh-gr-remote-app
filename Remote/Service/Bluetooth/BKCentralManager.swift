//
//  BKCentralManager.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import Foundation
import CoreBluetooth
import OSLog

final class BKCentralManager: NSObject {
    // MARK: - Type Aliases
    
    public typealias ConnectionHandler = (Result<BKPeripheral?, Error>) -> Void
    
    // MARK: - Devices
    
    private lazy var central = CBCentralManager(
        delegate: self,
        queue: nil,
        options: [CBCentralManagerOptionRestoreIdentifierKey: centralRestoreIdentifier]
    )
    private var peripheral: CBPeripheral?
    
    // MARK: - Private

    private var peripheralSpecification: BKPeripheralSpecification
    private let centralRestoreIdentifier: String
    private let peripheralConnectionOptions: [String: Any] = [
        CBConnectPeripheralOptionEnableAutoReconnect: true
    ]
    
    private var connectionHandler: ConnectionHandler?
    
    // MARK: - Logging

    private let logger = Logger(subsystem: "Bluetooth", category: "Central")
    
    // MARK: - Lifecycle
    
    init(for peripheralSpecification: BKPeripheralSpecification, restoreIdentifier: String) {
        self.peripheralSpecification = peripheralSpecification
        self.centralRestoreIdentifier = restoreIdentifier
    }
}

extension BKCentralManager {
    func connect(handler: @escaping ConnectionHandler) {
        connectionHandler = handler
        _ = central.state // connection trigger
    }
}


// MARK: - CBCentralManagerDelegate

extension BKCentralManager: CBCentralManagerDelegate {
    // MARK: - Monitoring Connections with Peripherals
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.debug("didConnect \(peripheral, privacy: .public)")
        connectionHandler?(.success(.init(peripheral)))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard
            let error = error as? CBError,
            let errorCode = CBError.Code(rawValue: error.errorCode)
        else {
            return
        }
        
        logger.debug("didDisconnectPeripheral \(peripheral, privacy: .public) errorCode \(error.localizedDescription, privacy: .public)")
        connectionHandler?(.success(nil))

        switch errorCode {
        case .peripheralDisconnected:
            // Device turned off or disconnected cause don't know us
            return
        default:
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: Error?) {
        logger.debug("didDisconnectPeripheral \(peripheral, privacy: .public) timestamp \(timestamp, privacy: .public) isReconnecting \(isReconnecting, privacy: .public) error \(error, privacy: .public)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard
            let error = error as? CBError,
            let errorCode = CBError.Code(rawValue: error.errorCode)
        else {
            return
        }
        
        logger.debug("didDisconnectPeripheral \(peripheral, privacy: .public) error \(error.localizedDescription, privacy: .public)")
        
        switch errorCode {
        case .peerRemovedPairingInformation:
            // TODO: Ask user to "Forget Bluetooth Device" and navigate to camera pairing screen
            central.cancelPeripheralConnection(peripheral)
        case .encryptionTimedOut:
            /* re */ central.connect(peripheral, options: peripheralConnectionOptions)
        default:
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        logger.debug("connectionEventDidOccur \(event.rawValue) for \(peripheral)")
    }
    
    // MARK: - Monitoring Connections with Peripherals
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        logger.debug("didDiscover \(peripheral, privacy: .public) advertisementData \(advertisementData.keys, privacy: .public) rssi \(RSSI, privacy: .public)")
        
        switch peripheralSpecification {
        case .identifier(let uuid):
            guard peripheral.identifier == uuid else {
                return
            }
        case .peripheral(let name):
            guard
                let regex = try? Regex(name),
                let name = peripheral.name,
                name.contains(regex)
            else {
                return
            }
        }

        central.stopScan()
        central.connect(peripheral, options: peripheralConnectionOptions)
            
        self.peripheral = peripheral
    }
    
    // MARK: - Monitoring the Central Manager’s State
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.debug("didUpdateState \(central.state, privacy: .public)")
        
        guard case .poweredOn = central.state else {
            return
        }
        
        if let peripheral = peripheral {
            if peripheral.state == .connected {
                connectionHandler?(.success(.init(peripheral)))
            } else {
                central.connect(peripheral, options: peripheralConnectionOptions)
            }
        } else {
            central.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        logger.debug("willRestore state \(dict, privacy: .public)")
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral], peripherals.count == 1 {
            self.peripheral = peripherals.first
        }
    }
    
    // MARK: - Monitoring the Central Manager’s Authorization
    
    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        logger.debug("didUpdateANCSAuthorizationFor \(peripheral, privacy: .public)")
    }
}
