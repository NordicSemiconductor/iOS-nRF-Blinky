//
//  BlinkyPeripheral.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 28/11/2017.
//  Modified by Aleksander Nowakowski on 13/02/2019
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol BlinkyDelegate {
    func blinkyDidConnect(ledSupported: Bool, buttonSupported: Bool)
    func blinkyDidDisconnect()
    func buttonStateChanged(isPressed: Bool)
    func ledStateChanged(isOn: Bool)
}

class BlinkyPeripheral: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
    
    // MARK: - Blinky services and charcteristics Identifiers
    
    public static let nordicBlinkyServiceUUID  = CBUUID.init(string: "00001523-1212-EFDE-1523-785FEABCD123")
    public static let buttonCharacteristicUUID = CBUUID.init(string: "00001524-1212-EFDE-1523-785FEABCD123")
    public static let ledCharacteristicUUID    = CBUUID.init(string: "00001525-1212-EFDE-1523-785FEABCD123")
    
    // MARK: - Properties
    
    private let centralManager                : CBCentralManager
    private let basePeripheral                : CBPeripheral
    public private(set) var advertisedName    : String?
    public private(set) var RSSI              : NSNumber
    
    public var delegate: BlinkyDelegate?
    
    // MARK: - Computed variables
    
    public var isConnected: Bool {
        return basePeripheral.state == .connected
    }

    // MARK: - Characteristic properties
    
    private var buttonCharacteristic: CBCharacteristic?
    private var ledCharacteristic   : CBCharacteristic?
    
    // MARK: - Public API
    
    /// Creates teh BlinkyPeripheral based on the received peripheral and advertisign data.
    /// The device name is obtaied from the advertising data, not from CBPeripheral object
    /// to avoid caching problems.
    init(withPeripheral peripheral: CBPeripheral, advertisementData advertisementDictionary: [String : Any], andRSSI currentRSSI: NSNumber, using manager: CBCentralManager) {
        centralManager = manager
        basePeripheral = peripheral
        RSSI = currentRSSI
        super.init()
        advertisedName = parseAdvertisementData(advertisementDictionary)
        basePeripheral.delegate = self
    }
    
    /// Connects to the Blinky device.
    public func connect() {
        centralManager.delegate = self
        print("Connecting to Blinky device...")
        centralManager.connect(basePeripheral, options: nil)
    }
    
    /// Cancels existing or pending connection.
    public func disconnect() {
        print("Cancelling connection...")
        centralManager.cancelPeripheralConnection(basePeripheral)
    }
    
    // MARK: - Blinky API
    
    /// Reads value of LED Characteristic. If such characteristic was not
    /// found, this method does nothing. If it was found, but does not have
    /// read property, the delegate will be notified with isOn = false.
    public func readLEDValue() {
        if let ledCharacteristic = ledCharacteristic {
            if ledCharacteristic.properties.contains(.read) {
                print("Reading LED characteristic...")
                basePeripheral.readValue(for: ledCharacteristic)
            } else {
                print("Can't read LED state")
                delegate?.ledStateChanged(isOn: false)
            }
        }
    }
    
    /// Reads value of Button Characteristic. If such characteristic was not
    /// found, this method does nothing. If it was found, but does not have
    /// read property, the delegate will be notified with isPressed = false.
    public func readButtonValue() {
        if let buttonCharacteristic = buttonCharacteristic {
            if buttonCharacteristic.properties.contains(.read) {
                print("Reading Button characteristic...")
                basePeripheral.readValue(for: buttonCharacteristic)
            } else {
                print("Can't read Button state")
                delegate?.buttonStateChanged(isPressed: false)
            }
        }
    }
    
    /// Sends a request to turn the LED on.
    public func turnOnLED() {
        writeLEDCharcateristic(withValue: Data([0x1]))
    }
    
    /// Sends a request to turn the LED off.
    public func turnOffLED() {
        writeLEDCharcateristic(withValue: Data([0x0]))
    }
    
    // MARK: - Implementation
    
    /// Starts service discovery, only for LED Button Service.
    private func discoverBlinkyServices() {
        print("Discovering LED Button service...")
        basePeripheral.delegate = self
        basePeripheral.discoverServices([BlinkyPeripheral.nordicBlinkyServiceUUID])
    }
    
    /// Starts characteristic discovery for LED and Button Characteristics.
    private func discoverCharacteristicsForBlinkyService(_ service: CBService) {
        print("Discovering LED and Button characteristrics...")
        basePeripheral.discoverCharacteristics(
            [BlinkyPeripheral.buttonCharacteristicUUID, BlinkyPeripheral.ledCharacteristicUUID],
            for: service)
    }
    
    /// Enables notification for given characteristic.
    /// If the characteristic does not have notify property, this method will
    /// call delegate's blinkyDidConnect method and try to read values
    /// of LED and Button.
    private func enableNotifications(for characteristic: CBCharacteristic) {
        if characteristic.properties.contains(.notify) {
            print("Enabling notifications for characteristic...")
            basePeripheral.setNotifyValue(true, for: characteristic)
        } else {
            delegate?.blinkyDidConnect(ledSupported: ledCharacteristic != nil, buttonSupported: true)
            readButtonValue()
            readLEDValue()
        }
    }
    
    /// Writes the value to the LED characteristic. Acceptable value
    /// is 1-byte long, with 0x00 to disable and 0x01 to enable the LED.
    /// If there is no LED characteristic, this method does nothing.
    /// If the characteristic does not have any of write properties
    /// this method also does nothing.
    private func writeLEDCharcateristic(withValue value: Data) {
        if let ledCharacteristic = ledCharacteristic {
            if ledCharacteristic.properties.contains(.write) {
                print("Writing LED value (with response)...")
                basePeripheral.writeValue(value, for: ledCharacteristic, type: .withResponse)
            } else if ledCharacteristic.properties.contains(.writeWithoutResponse) {
                print("Writing LED value... (without response)")
                basePeripheral.writeValue(value, for: ledCharacteristic, type: .withoutResponse)
                // peripheral(_:didWriteValueFor,error) will not be called after write without response
                // we are caling the delegate here
                didWriteValueToLED(value)
            } else {
                print("LED Characteristic is not writable")
            }
        }
    }
    
    /// A callback called when the LED value has been written.
    private func didWriteValueToLED(_ value: Data) {
        print("LED value written \(value[0])")
        delegate?.ledStateChanged(isOn: value[0] == 0x1)
    }
    
    /// A callback called when the Button characteristic value has changed.
    private func didReceiveButtonNotification(withValue value: Data) {
        print("Button value changed to: \(value[0])")
        delegate?.buttonStateChanged(isPressed: value[0] == 0x1)
    }

    private func parseAdvertisementData(_ advertisementDictionary: [String : Any]) -> String? {
        var advertisedName: String

        if let name = advertisementDictionary[CBAdvertisementDataLocalNameKey] as? String{
            advertisedName = name
        } else {
            advertisedName = "Unknown Device".localized
        }
        
        return advertisedName
    }
    
    // MARK: - NSObject protocols
    
    override func isEqual(_ object: Any?) -> Bool {
        if object is BlinkyPeripheral {
            let peripheralObject = object as! BlinkyPeripheral
            return peripheralObject.basePeripheral.identifier == basePeripheral.identifier
        } else if object is CBPeripheral {
            let peripheralObject = object as! CBPeripheral
            return peripheralObject.identifier == basePeripheral.identifier
        } else {
            return false
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Central Manager state changed to \(central.state)")
            delegate?.blinkyDidDisconnect()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == basePeripheral {
            print("Connected to Blinky")
            discoverBlinkyServices()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == basePeripheral {
            print("Blinky disconnected")
            delegate?.blinkyDidDisconnect()
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == buttonCharacteristic {
            if let value = characteristic.value {
                didReceiveButtonNotification(withValue: value)
            }
        } else if characteristic == ledCharacteristic {
            if let value = characteristic.value {
                didWriteValueToLED(value)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == buttonCharacteristic {
            print("Button notifications enabled")
            delegate?.blinkyDidConnect(ledSupported: ledCharacteristic != nil, buttonSupported: buttonCharacteristic != nil)
            readButtonValue()
            readLEDValue()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == BlinkyPeripheral.nordicBlinkyServiceUUID {
                    print("LED Button service found")
                    //Capture and discover all characteristics for the blinky service
                    discoverCharacteristicsForBlinkyService(service)
                    return
                }
            }
        }
        // Blinky service has not been found
        delegate?.blinkyDidConnect(ledSupported: false, buttonSupported: false)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == BlinkyPeripheral.buttonCharacteristicUUID {
                    print("Button characteristic found")
                    buttonCharacteristic = characteristic
                } else if characteristic.uuid == BlinkyPeripheral.ledCharacteristicUUID {
                    print("LED characteristic found")
                    ledCharacteristic = characteristic
                }
            }
        }
        
        // If Button caracteristic was found, try to enable notifications on it.
        if let buttonCharacteristic = buttonCharacteristic {
            enableNotifications(for: buttonCharacteristic)
        } else {
            // else, notify the delegate and try to read LED state.
            delegate?.blinkyDidConnect(ledSupported: ledCharacteristic != nil, buttonSupported: false)
            // This method will do nothing if LED characteristics was not found.
            readLEDValue()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // LED value has been written, let's read it to confirm.
        readLEDValue()
    }
}
