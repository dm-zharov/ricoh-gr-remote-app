//
//  BluetoothPeripheral.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import CoreBluetooth
import OSLog

class BKPeripheral: NSObject {
    // MARK: - Type Aliases

    public typealias DiscoverServicesContinuation = CheckedContinuation<[CBService], Error>
    public typealias DiscoverIncludedServicesContinuation = CheckedContinuation<[CBService], Error>
    public typealias DiscoverCharacteristicsContinuation = CheckedContinuation<[CBCharacteristic], Error>
    public typealias DiscoverDescriptorsContinuation = CheckedContinuation<[CBDescriptor], Error>
    public typealias UpdateCharacteristicValueContinuation = CheckedContinuation<Data?, Error>
    public typealias UpdateDescriptorValueContinuation = CheckedContinuation<Any?, Error>
    public typealias WriteCharacteristicValueContinuation = CheckedContinuation<Void, Error>
    public typealias WriteDescriptorValueContinuation = CheckedContinuation<Void, Error>
    public typealias UpdateNotificationValueHandler = (Result<Data?, Error>) -> Void
    
    // MARK: - Handlers
    
    private var discoverServicesContinuation: DiscoverServicesContinuation?
    private var discoverIncludedServicesContinuation: DiscoverIncludedServicesContinuation?
    private var discoverCharacteristicsContinuation: DiscoverCharacteristicsContinuation?
    private var discoverDescriptorsContinuation: DiscoverDescriptorsContinuation?
    private var updateCharacteristicValueContinuation: UpdateCharacteristicValueContinuation?
    private var updateDescriptorValueContinuation: UpdateDescriptorValueContinuation?
    private var writeCharacteristicValueContinuation: WriteCharacteristicValueContinuation?
    private var writeDescriptorValueContinuation: WriteDescriptorValueContinuation?
    private var notificationValueHandler: [CBUUID: UpdateNotificationValueHandler] = [:]
    
    // MARK: - Logging

    private let logger = Logger(subsystem: "Bluetooth", category: "Peripheral")
    
    // MARK: - Peripheral
    
    internal let peripheral: CBPeripheral!
    
    init(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
    }
    
    override init() {
        self.peripheral = nil
    }
}

// MARK: - Basic

extension BKPeripheral {
    func discoverServices(_ serviceUUIDs: [CBUUID]?) async throws -> [CBService] {
        try await withCheckedThrowingContinuation { (continuation: DiscoverServicesContinuation) in
            logger.debug("discoverServices \(serviceUUIDs ?? [], privacy: .public)")
            discoverServicesContinuation = continuation
            peripheral.discoverServices(serviceUUIDs)
        }
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) async throws -> [CBService] {
        try await withCheckedThrowingContinuation { (continuation: DiscoverIncludedServicesContinuation) in
            logger.debug("discoverIncludedServices \(includedServiceUUIDs ?? [], privacy: .public) for \(service, privacy: .public)")
            discoverIncludedServicesContinuation = continuation
            peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
        }
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) async throws -> [CBCharacteristic] {
        try await withCheckedThrowingContinuation { (continuation: DiscoverCharacteristicsContinuation) in
            logger.debug("discoverCharacteristics \(characteristicUUIDs ?? [], privacy: .public) for \(service, privacy: .public)")
            discoverCharacteristicsContinuation = continuation
            peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }
    
    func discoverDescriptors(for characteristic: CBCharacteristic) async throws -> [CBDescriptor] {
        try await withCheckedThrowingContinuation { (continuation: DiscoverDescriptorsContinuation) in
            logger.debug("discoverDescriptors for \(characteristic.uuid, privacy: .public)")
            discoverDescriptorsContinuation = continuation
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func readCharacteristicValue(_ characteristic: CBCharacteristic) async throws -> Data? {
        try await withCheckedThrowingContinuation { (continuation: UpdateCharacteristicValueContinuation) in
            logger.debug("readCharacteristicValue \(characteristic.uuid, privacy: .public)")
            updateCharacteristicValueContinuation = continuation
            peripheral.readValue(for: characteristic)
        }
    }
    
    func readDescriptorValue(_ descriptor: CBDescriptor) async throws -> Any? {
        try await withCheckedThrowingContinuation { (continuation: UpdateDescriptorValueContinuation) in
            logger.debug("readDescriptorValue \(descriptor.uuid, privacy: .public)")
            updateDescriptorValueContinuation = continuation
            peripheral.readValue(for: descriptor)
        }
    }
    
    func writeCharacteristicValue(_ characteristic: CBCharacteristic, _ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: WriteCharacteristicValueContinuation) in
            logger.debug("writeCharacteristicValue \(characteristic.uuid, privacy: .public) data \(data.debugDescription, privacy: .public)")
            writeDescriptorValueContinuation = continuation
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    func writeCharacteristicValue(_ characteristic: CBCharacteristic, _ data: Data) {
        logger.debug("writeCharacteristicValue \(characteristic.uuid, privacy: .public) data \(data.debugDescription, privacy: .public)")
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    func writeDescriptorValue(_ descriptor: CBDescriptor, _ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: WriteDescriptorValueContinuation) in
            logger.debug("writeDescriptorValue \(descriptor.uuid, privacy: .public) data \(data.debugDescription, privacy: .public)")
            writeDescriptorValueContinuation = continuation
            peripheral.writeValue(data, for: descriptor)
        }
    }

    func setCharacteristic(_ characteristic: CBCharacteristic, notifyHandler: UpdateNotificationValueHandler?) {
        if let notifyHandler {
            notificationValueHandler[characteristic.uuid] = notifyHandler
            peripheral.setNotifyValue(true, for: characteristic)
        } else {
            peripheral.setNotifyValue(false, for: characteristic)
        }
    }
}

extension BKPeripheral: CBPeripheralDelegate {
    // MARK: - Discovering Services
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.debug("didDiscoverServices \(peripheral.services ?? [], privacy: .public) error \(error?.localizedDescription ?? "", privacy: .public)")
        if let error {
            discoverServicesContinuation?.resume(throwing: error)
        } else {
            discoverServicesContinuation?.resume(returning: peripheral.services ?? [])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        logger.debug("didDiscoverIncludedServices \(service.includedServices ?? [], privacy: .public) for \(service.uuid, privacy: .public) error \(error?.localizedDescription ?? "", privacy: .public)")
        if let error {
            discoverIncludedServicesContinuation?.resume(throwing: error)
        } else {
            discoverIncludedServicesContinuation?.resume(returning: service.includedServices ?? [])
        }
    }
    
    // MARK: - Discovering Characteristics and their Descriptors
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.debug("didDiscoverCharacteristics \(service.characteristics ?? [], privacy: .public) for \(service.uuid, privacy: .public) error \(error?.localizedDescription ?? "", privacy: .public)")
        if let error {
            discoverCharacteristicsContinuation?.resume(throwing: error)
        } else {
            discoverCharacteristicsContinuation?.resume(returning: service.characteristics ?? [])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("didDiscoverDescriptors \(characteristic.descriptors ?? [], privacy: .public) for \(characteristic.uuid, privacy: .public) error \(error?.localizedDescription ?? "", privacy: .public)")
        if let error {
            discoverDescriptorsContinuation?.resume(throwing: error)
        } else {
            discoverDescriptorsContinuation?.resume(returning: characteristic.descriptors ?? [])
        }
    }
    
    // MARK: - Retrieving Characteristic and Descriptor Values
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("didUpdateValue \(characteristic.value ?? Data(), privacy: .public) for \(characteristic.uuid, privacy: .public) error \(error?.localizedDescription ?? "", privacy: .public)")
        if let error {
            updateCharacteristicValueContinuation?.resume(throwing: error)
        } else {
            updateCharacteristicValueContinuation?.resume(returning: characteristic.value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        logger.debug("didUpdateValue \(descriptor.value.debugDescription, privacy: .public) for \(descriptor.uuid, privacy: .public) error \(error?.localizedDescription ?? "", privacy: .public)")
        if let error {
            updateDescriptorValueContinuation?.resume(throwing: error)
        } else {
            updateDescriptorValueContinuation?.resume(returning: descriptor.value)
        }
    }
    
    // MARK: - Writing Characteristic and Descriptor Values
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("didWriteValue \(characteristic.value ?? Data(), privacy: .public) for \(characteristic.uuid, privacy: .public) error \(error?.localizedDescription ?? "", privacy: .public)")
        if let error {
            writeCharacteristicValueContinuation?.resume(throwing: error)
        } else {
            writeCharacteristicValueContinuation?.resume(returning: ())
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        logger.debug("didWriteValue \(descriptor.value.debugDescription, privacy: .public) for \(descriptor.uuid, privacy: .public) error \(error?.localizedDescription ?? "", privacy: .public)")
        if let error {
            writeDescriptorValueContinuation?.resume(throwing: error)
        } else {
            writeDescriptorValueContinuation?.resume(returning: ())
        }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) { }
    
    // MARK: - Managing Notifications for a Characteristic’s Value
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            notificationValueHandler[characteristic.uuid] = nil
        }
    }
    
    // MARK: - Retrieving a Peripheral’s RSSI Data
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) { }
    
    // MARK: - Monitoring Changes to a Peripheral’s Name or Services
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) { }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) { }
    
    // MARK: - Monitoring L2CAP Channels
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) { }
}
