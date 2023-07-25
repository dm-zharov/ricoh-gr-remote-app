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

    func geoTag() async throws -> Bool?
    func setGeoTag(_ enabled: Bool) async throws
    
    func dateTime() async throws -> Date?
    func syncDateTime() async throws
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
            let versionCharacteristic = characteristics[GR.CameraInformation.FirmwareRevision.uuid],
            let modelNumberCharacteristic = characteristics[GR.CameraInformation.ModelNumber.uuid],
            let serialNumberCharacteristic = characteristics[GR.CameraInformation.SerialNumber.uuid],
            let bluetoothCharacteristic = characteristics[GR.CameraInformation.BluetoothDeviceName.uuid]
        else {
            return nil
        }
        
        guard
            let version = try await readCharacteristicValue(versionCharacteristic),
            let modelNumber = try await readCharacteristicValue(modelNumberCharacteristic),
            let serialNumber = try await readCharacteristicValue(serialNumberCharacteristic),
            let bluetooth = try await readCharacteristicValue(bluetoothCharacteristic)
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
    
    func geoTag() async throws -> Bool? {
        guard
            let cameraInformation = try await discoverServices([GR.Camera.uuid])[GR.Camera.uuid],
            let geoTag = try await discoverCharacteristics(
                [GR.Camera.GEOTag.uuid], for: cameraInformation
            )[GR.Camera.GEOTag.uuid]
        else {
            return nil
        }
        
        guard
            let value = try await readCharacteristicValue(geoTag)
        else {
            return nil
        }
        
        let uint8 = value.withUnsafeBytes { bytes in
            bytes.load(as: UInt8.self)
        }
        
        return uint8.bool()
    }
    
    func setGeoTag(_ enabled: Bool) async throws {
        guard let geoTag = attributes[GR.Camera.GEOTag.uuid] as? CBCharacteristic else {
            return assertionFailure()
        }
        try await writeCharacteristicValue(geoTag, enabled.uint8().data(), type: .withResponse)
    }
    
    func dateTime() async throws -> Date? {
        guard
            let cameraInformation = try await discoverServices([GR.Camera.uuid])[GR.Camera.uuid],
            let dateTime = try await discoverCharacteristics(
                [GR.Camera.DateTime.uuid], for: cameraInformation
            )[GR.Camera.DateTime.uuid]
        else {
            return nil
        }
        
        guard
            let value = try await readCharacteristicValue(dateTime)
        else {
            return nil
        }
        
        guard value.count == 7 else {
            return nil
        }
        
        let year: UInt16 = value[0...1].withUnsafeBytes { $0.load(as: UInt16.self) }
        let month: UInt8 = value[2]
        let day: UInt8 = value[3]
        let hour: UInt8 = value[4]
        let minute: UInt8 = value[5]
        let second: UInt8 = value[6]
        
        let dateComponents = DateComponents(
            timeZone: .gmt,
            year: Int(year),
            month: Int(month),
            day: Int(day),
            hour: Int(hour),
            minute: Int(minute), second: Int(second)
        )
        
        return Calendar.current.date(from: dateComponents)
    }
    
    func syncDateTime() async throws {
        guard let dateTime = attributes[GR.Camera.DateTime.uuid] as? CBCharacteristic else {
            return assertionFailure()
        }
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: .now
        )
        
        let year: UInt16 = UInt16(dateComponents.year ?? 0)
        let month: UInt8 = UInt8(dateComponents.month ?? 0)
        let day: UInt8 = UInt8(dateComponents.day ?? 0)
        let hour: UInt8 = UInt8(dateComponents.hour ?? 0)
        let minute: UInt8 = UInt8(dateComponents.minute ?? 0)
        let second: UInt8 = UInt8(dateComponents.second ?? 0)
        
        let value = Data([
            UInt8(year & 0x00FF), // Low byte,
            UInt8((year & 0xFF00) >> 8), // // High byte (8 most significant bits)
            month,
            day,
            hour,
            minute,
            second
        ])
        
        try await writeCharacteristicValue(dateTime, value, type: .withResponse)
    }
}

class Virtual: CameraConnector {
    var isReady: Bool {
        true
    }
    
    func info() async throws -> CameraInfo? {
        nil
    }
    
    func geoTag() async throws -> Bool? {
        nil
    }
    
    func setGeoTag(_ enabled: Bool) async throws { }
    
    func dateTime() async throws -> Date? {
        nil
    }
    
    func syncDateTime() async throws { }
}

extension Collection where Element: CBAttribute {
    subscript(uuid: CBUUID) -> Self.Element? {
        first(where: { $0.uuid == uuid })
    }
}

extension UInt8 {
    func bool() -> Bool {
        switch self {
        case 0x01:
            return true
        case 0x00:
            return false
        default:
            return false
        }
    }
    
    func data() -> Data {
        withUnsafeBytes(of: self) { Data($0) }
    }
}

extension Bool {
    func uint8() -> UInt8 {
        switch self {
        case true:
            return 0x01
        case false:
            return 0x00
        }
    }
}
