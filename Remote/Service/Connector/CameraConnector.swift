//
//  CameraConnector.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import Foundation
import CoreBluetooth

enum MyError: Error {
    case unknown
}

protocol CameraConnector: RemoteConnector {
    func info() async throws -> CameraInfo?
    func batteryLevel() async throws -> BatteryLevel?
    func geoTag() async throws -> Bool?
}

extension BKPeripheral: CameraConnector {
    func info() async throws -> CameraInfo? {
        guard
            let cameraInformation = try await discoverServices(
                [GR.CameraInformation.uuid]
            ).first(where: { $0.uuid == GR.CameraInformation.uuid })
        else {
            return nil
        }

        let characteristics = try await discoverCharacteristics([
            GR.CameraInformation.FirmwareRevision.uuid,
            GR.CameraInformation.ModelNumber.uuid,
            GR.CameraInformation.SerialNumber.uuid,
            GR.CameraInformation.BluetoothDeviceName.uuid
        ], for: cameraInformation)
        
        guard
            let version = try await readCharacteristicValue(characteristics[GR.CameraInformation.FirmwareRevision.uuid]),
            let modelNumber = try await readCharacteristicValue(characteristics[GR.CameraInformation.ModelNumber.uuid]),
            let serialNumber = try await readCharacteristicValue(characteristics[GR.CameraInformation.SerialNumber.uuid]),
            let bluetooth = try await readCharacteristicValue(characteristics[GR.CameraInformation.BluetoothDeviceName.uuid])
        else {
            return nil
        }

        return CameraInfo(
            version: String(data: version, encoding: .utf8),
            modelNumber: String(data: modelNumber, encoding: .utf8),
            serialNumber: String(data: serialNumber, encoding: .utf8),
            bluetooth: String(data: bluetooth, encoding: .utf8)
        )
    }
    
    func batteryLevel() async throws -> BatteryLevel? {
        let cameraInformation = try await discoverServices([GR.Camera.uuid])[GR.Camera.uuid]

        let batteryLevel = try await discoverCharacteristics(
            [GR.Camera.BatteryLevel.uuid], for: cameraInformation
        )[GR.Camera.BatteryLevel.uuid]

        guard
            let value = try await readCharacteristicValue(batteryLevel)
        else {
            return nil
        }
        
        print(value)
        
        return nil
    }
    
    func geoTag() async throws -> Bool? {
        let cameraInformation = try await discoverServices([GR.Camera.uuid])[GR.Camera.uuid]
        
        let geoTag = try await discoverCharacteristics(
            [GR.Camera.GEOTag.uuid], for: cameraInformation
        )[GR.Camera.GEOTag.uuid]
        
        guard
            let value = try await readCharacteristicValue(geoTag)
        else {
            return nil
        }
        
        print(value)
        
        return nil
    }
}

class Virtual: CameraConnector {
    var isReady: Bool {
        true
    }
    
    func info() async throws -> CameraInfo? {
        nil
    }
    
    func batteryLevel() async throws -> BatteryLevel? {
        nil
    }
    
    func geoTag() async throws -> Bool? {
        nil
    }
}

extension Collection where Element: CBAttribute {
    subscript(uuid: CBUUID) -> Self.Element {
        first(where: { $0.uuid == uuid })!
    }
}
