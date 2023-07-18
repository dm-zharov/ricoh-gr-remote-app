//
//  CBUUID+RICOH.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import CoreBluetooth

enum GR {
    enum CameraInformation {
        enum FirmwareRevision {
            static let uuid = CBUUID(string: "B4EB8905-7411-40A6-A367-2834C2157EA7")
        }
        enum ManufacturerName {
            static let uuid = CBUUID(string: "F5666A48-6A74-40AE-A817-3C9B3EFB59A6")
        }
        enum ModelNumber {
            static let uuid = CBUUID(string: "35FE6272-6AA5-44D9-88E1-F09427F51A71")
        }
        enum SerialNumber {
            static let uuid = CBUUID(string: "0D2FC4D5-5CB3-4CDE-B519-445E599957D8")
        }
        enum BluetoothDeviceName {
            static let uuid = CBUUID(string: "97E34DA2-2E1A-405B-B80D-F8F0AA9CC51C")
        }
        enum BluetoothMACAddress {
            static let uuid = CBUUID(string: "1C5C6C55-8E57-4B32-AD80-B124AE229DEC")
        }
        static let uuid = CBUUID(string: "9A5ED1C5-74CC-4C50-B5B6-66A48E7CCFF1")
    }
    
    enum Camera {
        enum CameraServiceNotification {
            static let uuid = CBUUID(string: "FAA0AEAF-1654-4842-A139-F4E1C1E722AC")
        }
        enum CameraPower {
            static let uuid = CBUUID(string: "B58CE84C-0666-4DE9-BEC8-2D27B27B3211")
        }
        static let uuid = CBUUID(string: "4B445988-CAA0-4DD3-941D-37B4F52ACA86")
    }
    enum Shooting {
        enum ShootingServiceNotification {
            static let uuid = CBUUID(string: "671466A5-5535-412E-AC4F-8B2F06AF2237")
        }
        enum Aperture {
            static let uuid = CBUUID(string: "3911F22D-9771-479D-B2B9-F729D9BAF9DC")
        }
        enum OperationRequest {
            static let uuid = CBUUID(string: "559644B8-E0BC-4011-929B-5CF9199851E7")
        }
        static let uuid = CBUUID(string: "9F00F387-8345-4BBC-8B92-B87B52E3091A")
    }
    enum GPSControlCommand {
        static let uuid = CBUUID(string: "84A0DD62-E8AA-4D0F-91DB-819B6724C69E")
    }
    enum WLANControlCommand {
        static let uuid = CBUUID(string: "F37F568F-9071-445D-A938-5441F2E82399")
    }
    enum BluetoothControlCommand {
        enum PairedDeviceName {
            static let uuid = CBUUID(string: "FE3A32F8-A189-42DE-A391-B81AE4DAA76")
        }
        static let uuid = CBUUID(string: "0F291746-0C80-4726-87A7-3C501FD3B4B6")
    }
}
