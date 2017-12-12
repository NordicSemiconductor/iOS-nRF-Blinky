//
//  BlinkyTableViewCell.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 28/11/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit

class BlinkyTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "blinkyPeripheralCell"
    private var lastUpdateTimestamp = Date()
    @IBOutlet weak var peripheralName: UILabel!
    @IBOutlet weak var peripheralRSSIIcon: UIImageView!

    private var peripheral: BlinkyPeripheral!

    public func setupViewWithPeripheral(_ aPeripheral: BlinkyPeripheral) {
        peripheral = aPeripheral
        peripheralName.text = aPeripheral.advertisedName

        if peripheral!.RSSI.decimalValue < -60 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_2")
        } else if peripheral!.RSSI.decimalValue < -50 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_3")
        } else if peripheral!.RSSI.decimalValue < -30 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_4")
        } else {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_1")
        }
    }
    
    public func peripheralUpdatedAdvertisementData(_ aPeripheral: BlinkyPeripheral) {
        if Date().timeIntervalSince(lastUpdateTimestamp) > 1.0 {
            lastUpdateTimestamp = Date()
            setupViewWithPeripheral(aPeripheral)
        }
    }
}
