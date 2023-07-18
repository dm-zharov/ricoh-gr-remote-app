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

    public typealias DiscoverServicesHandler = ([CBService]) -> Void
    public typealias DiscoverIncludedServicesHandler = ([CBService]) -> Void
    public typealias DiscoverCharacteristicsHandler = ([CBCharacteristic]) -> Void
    public typealias DiscoverDescriptorsHandler = ([CBDescriptor]) -> Void
    public typealias UpdateCharacteristicValue = (Data?) -> Void
    public typealias UpdateDescriptorValue = (Any?) -> Void
    public typealias WriteCharacteristicValue = () -> Void
    public typealias WriteDescriptorValue = () -> Void
    public typealias UpdateNotificationValue = (Data?) -> Void
    
    // MARK: - Handlers
    
    private var discoverServicesHandlers: [DiscoverServicesHandler] = []
    private var discoverIncludedServicesHandlers: [DiscoverIncludedServicesHandler] = []
    private var discoverCharacteristicsHandlers: [DiscoverCharacteristicsHandler] = []
    private var discoverDescriptorsHandlers: [DiscoverDescriptorsHandler] = []
    private var updateCharacteristicValueHandlers: [UpdateCharacteristicValue] = []
    private var updateDescriptorValueHandlers: [UpdateDescriptorValue] = []
    private var writeCharacteristicValueHandlers: [WriteCharacteristicValue] = []
    private var writeDescriptorValueHandlers: [WriteDescriptorValue] = []
    private var notificationValueHandlers: [CBUUID: UpdateNotificationValue] = [:]
    
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

// MARK: - Convenient

extension BKPeripheral {
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for serviceUUID: CBUUID, handler: @escaping DiscoverCharacteristicsHandler) {
        discoverServices([serviceUUID]) { [weak self] services in
            if let service = services.first(where: { $0.uuid == serviceUUID }) {
                self?.discoverCharacteristics(characteristicUUIDs, for: service) { characteristics in
                    handler(characteristics)
                }
            }
        }
    }
    
    func readCharacteristicValue(_ characteristicUUID: CBUUID, for serviceUUID: CBUUID, handler: @escaping UpdateCharacteristicValue) {
        discoverCharacteristics([characteristicUUID], for: serviceUUID) { [weak self] characteristics in
            if let characteristic = characteristics.first(where: { $0.uuid == characteristicUUID }) {
                self?.readCharacteristicValue(characteristic) { value in
                    handler(characteristic.value)
                }
            }
        }
    }
}

// MARK: - Basic

extension BKPeripheral {
    func discoverServices(_ serviceUUIDs: [CBUUID]?, handler: @escaping DiscoverServicesHandler) {
        discoverServicesHandlers.append(handler)
        peripheral.discoverServices(serviceUUIDs)
    }
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?) async -> [CBService] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[CBService], Never>) in
            discoverServices(serviceUUIDs) { services in
                continuation.resume(returning: services)
            }
        }
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService, handler: @escaping DiscoverIncludedServicesHandler) {
        discoverIncludedServicesHandlers.append(handler)
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) async -> [CBService] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[CBService], Never>) in
            discoverIncludedServices(includedServiceUUIDs, for: service) { services in
                continuation.resume(returning: services)
            }
        }
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService, handler: @escaping DiscoverCharacteristicsHandler) {
        discoverCharacteristicsHandlers.append(handler)
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) async -> [CBCharacteristic] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[CBCharacteristic], Never>) in
            discoverCharacteristics(characteristicUUIDs, for: service) { characteristics in
                continuation.resume(returning: characteristics)
            }
        }
    }
    
    func discoverDescriptors(for characteristic: CBCharacteristic, handler: @escaping DiscoverDescriptorsHandler) {
        discoverDescriptorsHandlers.append(handler)
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    func discoverDescriptors(for characteristic: CBCharacteristic) async -> [CBDescriptor] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[CBDescriptor], Never>) in
            discoverDescriptors(for: characteristic) { descriptors in
                continuation.resume(returning: descriptors)
            }
        }
    }
    
    func readCharacteristicValue(_ characteristic: CBCharacteristic, handler: @escaping UpdateCharacteristicValue) {
        updateCharacteristicValueHandlers.append(handler)
        peripheral.readValue(for: characteristic)
    }
    
    func readCharacteristicValue(_ characteristic: CBCharacteristic) async -> Data? {
        await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            readCharacteristicValue(characteristic) { value in
                continuation.resume(returning: value)
            }
        }
    }
    
    func readDescriptorValue(_ descriptor: CBDescriptor, handler: @escaping UpdateDescriptorValue) {
        updateDescriptorValueHandlers.append(handler)
        peripheral.readValue(for: descriptor)
    }
    
    func writeCharacteristicValue(_ characteristic: CBCharacteristic, _ data: Data, handler: WriteCharacteristicValue?) {
        if let handler {
            writeCharacteristicValueHandlers.append(handler)
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        } else {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }
    
    func writeDescriptorValue(_ descriptor: CBDescriptor, _ data: Data, handler: @escaping WriteDescriptorValue) {
        writeDescriptorValueHandlers.append(handler)
        peripheral.writeValue(data, for: descriptor)
    }

    func setCharacteristicNotifyValue(_ characteristic: CBCharacteristic, handler: UpdateNotificationValue?) {
        if let handler {
            notificationValueHandlers[characteristic.uuid] = handler
            peripheral.setNotifyValue(true, for: characteristic)
        } else {
            peripheral.setNotifyValue(false, for: characteristic)
        }
    }
}

extension BKPeripheral: CBPeripheralDelegate {
    // MARK: - Discovering Services
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        discoverServicesHandlers.forEach { $0(peripheral.services ?? []) }
        discoverServicesHandlers.removeAll()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        discoverIncludedServicesHandlers.forEach { $0(service.includedServices ?? []) }
        discoverIncludedServicesHandlers.removeAll()
    }
    
    // MARK: - Discovering Characteristics and their Descriptors
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        discoverCharacteristicsHandlers.forEach { $0(service.characteristics ?? []) }
        discoverCharacteristicsHandlers.removeAll()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        discoverDescriptorsHandlers.forEach { $0(characteristic.descriptors ?? []) }
        discoverDescriptorsHandlers.removeAll()
    }
    
    // MARK: - Retrieving Characteristic and Descriptor Values
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        notificationValueHandlers[characteristic.uuid]?(characteristic.value)
        updateCharacteristicValueHandlers.forEach { $0(characteristic.value) }
        updateCharacteristicValueHandlers.removeAll()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        updateDescriptorValueHandlers.forEach { $0(descriptor.value) }
        updateDescriptorValueHandlers.removeAll()
    }
    
    // MARK: - Writing Characteristic and Descriptor Values
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        writeCharacteristicValueHandlers.forEach { $0() }
        writeCharacteristicValueHandlers.removeAll()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        writeDescriptorValueHandlers.forEach { $0() }
        writeDescriptorValueHandlers.removeAll()
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) { }
    
    // MARK: - Managing Notifications for a Characteristic’s Value
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            notificationValueHandlers[characteristic.uuid] = nil
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
