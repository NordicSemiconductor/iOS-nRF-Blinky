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
    //MARK: - Blinky services and charcteristics Identifiers
    //
    public static let nordicBlinkyServiceUUID  = CBUUID.init(string: "00001523-1212-EFDE-1523-785FEABCD123")
    public static let buttonCharacteristicUUID = CBUUID.init(string: "00001524-1212-EFDE-1523-785FEABCD123")
    public static let ledCharacteristicUUID    = CBUUID.init(string: "00001525-1212-EFDE-1523-785FEABCD123")
    //MARK: - Properties
    //
    public private(set) var basePeripheral      : CBPeripheral
    public private(set) var advertisedName      : String?
    public private(set) var RSSI                : NSNumber
    public private(set) var advertisedServices  : [CBUUID]?
    
    //MARK: - Callback handlers
    private var ledCallbackHandler : ((Bool) -> (Void))?
    private var buttonPressHandler : ((Bool) -> (Void))?

    //MARK: - Services and Characteristic properties
    //
    private             var blinkyService       : CBService?
    private             var buttonCharacteristic: CBCharacteristic?
    private             var ledCharacteristic   : CBCharacteristic?

    init(withPeripheral aPeripheral: CBPeripheral, advertisementData anAdvertisementDictionary: [String : Any], andRSSI anRSSI: NSNumber) {
        basePeripheral = aPeripheral
        RSSI = anRSSI
        super.init()
        (advertisedName, advertisedServices) = parseAdvertisementData(anAdvertisementDictionary)
        basePeripheral.delegate = self
    }
    
    public func setLEDCallback(aCallbackHandler: @escaping (Bool) -> (Void)){
        ledCallbackHandler = aCallbackHandler
    }

    public func setButtonCallback(aCallbackHandler: @escaping (Bool) -> (Void)) {
        buttonPressHandler = aCallbackHandler
    }
    
    public func removeButtonCallback() {
        buttonPressHandler = nil
    }
    
    public func removeLEDCallback() {
        ledCallbackHandler = nil
    }

    public func discoverBlinkyServices() {
        print("Discovering blinky service")
        basePeripheral.delegate = self
        basePeripheral.discoverServices([BlinkyPeripheral.nordicBlinkyServiceUUID])
    }
    
    public func discoverCharacteristicsForBlinkyService(_ aService: CBService) {
        basePeripheral.discoverCharacteristics([BlinkyPeripheral.buttonCharacteristicUUID,
                                            BlinkyPeripheral.ledCharacteristicUUID],
                                           for: aService)
    }
    
    public func enableButtonNotifications(_ buttonCharacteristic: CBCharacteristic) {
        print("Enabling notifications for button characteristic")
        basePeripheral.setNotifyValue(true, for: buttonCharacteristic)
    }
    
    public func readLEDValue() {
        if let ledCharacteristic = ledCharacteristic {
            basePeripheral.readValue(for: ledCharacteristic)
        }
    }
    
    public func readButtonValue() {
        if let buttonCharacteristic = buttonCharacteristic {
            basePeripheral.readValue(for: buttonCharacteristic)
        }
    }

    public func didWriteValueToLED(_ aValue: Data) {
        print("LED value written \(aValue[0])")
        if aValue[0] == 1 {
            ledCallbackHandler?(true)
        } else {
            ledCallbackHandler?(false)
        }
    }
    
    public func didReceiveButtonNotificationWithValue(_ aValue: Data) {
        print("Button value changed to: \(aValue[0])")
        if aValue[0] == 1 {
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
    
    private func writeLEDCharcateristicValue(_ aValue: Data) {
        guard let ledCharacteristic = ledCharacteristic else {
            print("LED characteristic is not present, nothing to be done")
            return
        }
        basePeripheral.writeValue(aValue, for: ledCharacteristic, type: .withResponse)
    }

    private func parseAdvertisementData(_ anAdvertisementDictionary: [String : Any]) -> (String?, [CBUUID]?) {
        var advertisedName: String
        var advertisedServices: [CBUUID]

        if let name = anAdvertisementDictionary[CBAdvertisementDataLocalNameKey] as? String{
            advertisedName = name
        } else {
            advertisedName = "N/A"
        }
        if let services = anAdvertisementDictionary[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            advertisedServices = services
        } else {
            advertisedServices = [CBUUID]()
        }
        
        return (advertisedName, advertisedServices)
    }
    
    //MARK: - NSObject protocols
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
    
    //MARK: - CBPeripheralDelegate
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
        if characteristic.uuid == buttonCharacteristic?.uuid {
            print("Notification state is now \(characteristic.isNotifying) for Button characteristic")
            readButtonValue()
            readLEDValue()
        } else {
            print("Notification state is now \(characteristic.isNotifying) for an unknown characteristic with UUID: \(characteristic.uuid.uuidString)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for aService in services {
                if aService.uuid == BlinkyPeripheral.nordicBlinkyServiceUUID {
                    print("Discovered Blinky service!")
                    //Capture and discover all characteristics for the blinky service
                    blinkyService = aService
                    discoverCharacteristicsForBlinkyService(blinkyService!)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if service == blinkyService {
            print("Discovered characteristics for blinky service")
            if let characteristics = service.characteristics {
                for aCharacteristic in characteristics {
                    if aCharacteristic.uuid == BlinkyPeripheral.buttonCharacteristicUUID {
                        print("Discovered Blinky button characteristic")
                        buttonCharacteristic = aCharacteristic
                        enableButtonNotifications(buttonCharacteristic!)
                    } else if aCharacteristic.uuid == BlinkyPeripheral.ledCharacteristicUUID {
                        print("Discovered Blinky LED characteristic")
                        ledCharacteristic = aCharacteristic
                    }
                }
            }
        } else {
            print("Discovered characteristics for an unnknown service with UUID: \(service.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == ledCharacteristic {
            peripheral.readValue(for: ledCharacteristic!)
        }
    }
}
