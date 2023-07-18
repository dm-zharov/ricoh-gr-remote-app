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
    func info() async  -> CameraInfo?
    func powerState() async -> Bool?
    func releaseShutter(completion: @escaping () -> ())
}

extension BKPeripheral: CameraConnector {
    func info() async -> CameraInfo? {
        guard
            let cameraInformation = await discoverServices(
                [GR.CameraInformation.uuid]
            ).first(where: { $0.uuid == GR.CameraInformation.uuid })
        else {
            return nil
        }

        let characteristics = await discoverCharacteristics([
            GR.CameraInformation.BluetoothDeviceName.uuid,
            GR.CameraInformation.FirmwareRevision.uuid,
            GR.CameraInformation.ManufacturerName.uuid,
            GR.CameraInformation.ModelNumber.uuid,
            GR.CameraInformation.SerialNumber.uuid
        ], for: cameraInformation)
        
        return CameraInfo(
            version:
                await readCharacteristicValue(characteristics[GR.CameraInformation.FirmwareRevision.uuid]).stringValue,
            modelNumber:
                await readCharacteristicValue(characteristics[GR.CameraInformation.ModelNumber.uuid]).stringValue,
            serialNumber:
                await readCharacteristicValue(characteristics[GR.CameraInformation.SerialNumber.uuid]).stringValue,
            bluetooth:
                await readCharacteristicValue(characteristics[GR.CameraInformation.BluetoothDeviceName.uuid]).stringValue
        )
    }
    
    func powerState() async -> Bool? {
        nil
    }
    
    func releaseShutter(completion: @escaping () -> ()) {
        
    }
}

class Virtual: CameraConnector {
    var isReady: Bool {
        true
    }
    
    func info() async -> CameraInfo? {
        nil
    }
    
    func powerState() async -> Bool? {
        nil
    }
    
    func releaseShutter(completion: @escaping () -> ()) {
        
    }
}

extension Collection where Element: CBAttribute {
    subscript(uuid: CBUUID) -> Self.Element {
        first(where: { $0.uuid == uuid })!
    }
}

extension Optional where Wrapped == Data {
    var stringValue: String? {
        switch self {
        case .some(let data):
            return String(data: data, encoding: .utf8)
        case .none:
            return nil
        }
    }
}
