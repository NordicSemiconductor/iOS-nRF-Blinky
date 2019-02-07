//
//  BlinkyPeripheral.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 28/11/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth

class BlinkyPeripheral: NSObject, CBPeripheralDelegate {
    
    // MARK: - Blinky services and charcteristics Identifiers
    
    public static let nordicBlinkyServiceUUID  = CBUUID.init(string: "00001523-1212-EFDE-1523-785FEABCD123")
    public static let buttonCharacteristicUUID = CBUUID.init(string: "00001524-1212-EFDE-1523-785FEABCD123")
    public static let ledCharacteristicUUID    = CBUUID.init(string: "00001525-1212-EFDE-1523-785FEABCD123")
    
    // MARK: - Properties
    
    public private(set) var basePeripheral    : CBPeripheral
    public private(set) var advertisedName    : String?
    public private(set) var RSSI              : NSNumber
    public private(set) var advertisedServices: [CBUUID]?
    
    // MARK: - Callback handlers
    
    private var ledCallbackHandler: ((Bool) -> (Void))?
    private var buttonPressHandler: ((Bool) -> (Void))?

    // MARK: - Services and Characteristic properties
    
    private var blinkyService       : CBService?
    private var buttonCharacteristic: CBCharacteristic?
    private var ledCharacteristic   : CBCharacteristic?

    init(withPeripheral peripheral: CBPeripheral, advertisementData advertisementDictionary: [String : Any], andRSSI currentRSSI: NSNumber) {
        basePeripheral = peripheral
        RSSI = currentRSSI
        super.init()
        (advertisedName, advertisedServices) = parseAdvertisementData(advertisementDictionary)
        basePeripheral.delegate = self
    }
    
    public func setLEDCallback(_ handler: @escaping (Bool) -> (Void)) {
        ledCallbackHandler = handler
    }

    public func setButtonCallback(_ handler: @escaping (Bool) -> (Void)) {
        buttonPressHandler = handler
    }
    
    public func removeButtonCallback() {
        buttonPressHandler = nil
    }
    
    public func removeLEDCallback() {
        ledCallbackHandler = nil
    }

    public func discoverBlinkyServices() {
        print("Discovering LED Button service...")
        basePeripheral.delegate = self
        basePeripheral.discoverServices([BlinkyPeripheral.nordicBlinkyServiceUUID])
    }
    
    public func discoverCharacteristicsForBlinkyService(_ service: CBService) {
        print("Discovering LED and Button characteristrics...")
        basePeripheral.discoverCharacteristics([BlinkyPeripheral.buttonCharacteristicUUID,
                                            BlinkyPeripheral.ledCharacteristicUUID],
                                           for: service)
    }
    
    public func enableButtonNotifications(_ buttonCharacteristic: CBCharacteristic) {
        print("Enabling notifications for Button characteristic...")
        basePeripheral.setNotifyValue(true, for: buttonCharacteristic)
    }
    
    public func readLEDValue() {
        if let ledCharacteristic = ledCharacteristic {
            print("Reading LED characteristic...")
            basePeripheral.readValue(for: ledCharacteristic)
        }
    }
    
    public func readButtonValue() {
        if let buttonCharacteristic = buttonCharacteristic {
            print("Reading Button characteristic...")
            basePeripheral.readValue(for: buttonCharacteristic)
        }
    }

    public func didWriteValueToLED(_ value: Data) {
        print("LED value written \(value[0])")
        if value[0] == 1 {
            ledCallbackHandler?(true)
        } else {
            ledCallbackHandler?(false)
        }
    }
    
    public func didReceiveButtonNotificationWithValue(_ value: Data) {
        print("Button value changed to: \(value[0])")
        if value[0] == 1 {
            buttonPressHandler?(true)
        } else {
            buttonPressHandler?(false)
        }
    }
    
    public func turnOnLED() {
        writeLEDCharcateristicValue(Data([0x1]))
    }
    
    public func turnOffLED() {
        writeLEDCharcateristicValue(Data([0x0]))
    }
    
    private func writeLEDCharcateristicValue(_ value: Data) {
        guard let ledCharacteristic = ledCharacteristic else {
            print("LED characteristic is not present, nothing to be done")
            return
        }
        print("Writing LED value...")
        basePeripheral.writeValue(value, for: ledCharacteristic, type: .withResponse)
    }

    private func parseAdvertisementData(_ advertisementDictionary: [String : Any]) -> (String?, [CBUUID]?) {
        var advertisedName: String
        var advertisedServices: [CBUUID]

        if let name = advertisementDictionary[CBAdvertisementDataLocalNameKey] as? String{
            advertisedName = name
        } else {
            advertisedName = "N/A"
        }
        if let services = advertisementDictionary[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            advertisedServices = services
        } else {
            advertisedServices = [CBUUID]()
        }
        
        return (advertisedName, advertisedServices)
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
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == buttonCharacteristic {
            if let aValue = characteristic.value {
                didReceiveButtonNotificationWithValue(aValue)
            }
        } else if characteristic == ledCharacteristic {
            if let aValue = characteristic.value {
                didWriteValueToLED(aValue)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == buttonCharacteristic {
            print("Button notifications enabled")
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
                    blinkyService = service
                    discoverCharacteristicsForBlinkyService(blinkyService!)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if service == blinkyService {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.uuid == BlinkyPeripheral.buttonCharacteristicUUID {
                        print("Button characteristic found")
                        buttonCharacteristic = characteristic
                        enableButtonNotifications(buttonCharacteristic!)
                    } else if characteristic.uuid == BlinkyPeripheral.ledCharacteristicUUID {
                        print("LED characteristic found")
                        ledCharacteristic = characteristic
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == ledCharacteristic {
            print("Reading LED characteristic...")
            peripheral.readValue(for: ledCharacteristic!)
        }
    }
}
