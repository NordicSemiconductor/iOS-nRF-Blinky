//
//  BlinkyViewController.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 01/12/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth

class BlinkyViewController: UITableViewController, BlinkyDelegate {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var ledStateLabel: UILabel!
    @IBOutlet weak var ledToggleSwitch: UISwitch!
    @IBOutlet weak var buttonStateLabel: UILabel!
    
    @IBAction func ledToggleSwitchDidChange(_ sender: Any) {
        handleSwitchValueChange(newValue: ledToggleSwitch.isOn)
    }

    // MARK: - Properties

    private var hapticGenerator: NSObject? // Only available on iOS 10 and above
    private var blinkyPeripheral: BlinkyPeripheral!
    private var centralManager: CBCentralManager!
    
    // MARK: - Public API
    
    public func setPeripheral(_ peripheral: BlinkyPeripheral) {
        blinkyPeripheral = peripheral
        title = peripheral.advertisedName
        peripheral.delegate = self
    }
    
    // MARK: - UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !blinkyPeripheral.isConnected else {
            // View is coming back from a swipe, everything is already setup
            return
        }
        prepareHaptics()
        blinkyPeripheral.connect()
    }

    override func viewDidDisappear(_ animated: Bool) {
        blinkyPeripheral.disconnect()
        super.viewDidDisappear(animated)
    }
    
    // MARK: - Implementation
    
    private func handleSwitchValueChange(newValue isOn: Bool){
        if isOn {
            blinkyPeripheral.turnOnLED()
            ledStateLabel.text = "ON".localized
        } else {
            blinkyPeripheral.turnOffLED()
            ledStateLabel.text = "OFF".localized
        }
    }

    /// This will run on iOS 10 or above
    /// and will generate a tap feedback when the button is tapped on the Dev kit.
    private func prepareHaptics() {
        if #available(iOS 10.0, *) {
            hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
            (hapticGenerator as? UIImpactFeedbackGenerator)?.prepare()
        }
    }
    
    /// Generates a tap feedback on iOS 10 or above.
    private func buttonTapHapticFeedback() {
        if #available(iOS 10.0, *) {
            (hapticGenerator as? UIImpactFeedbackGenerator)?.impactOccurred()
        }
    }
    
    // MARK: - Blinky Delegate
    
    func blinkyDidConnect(ledSupported: Bool, buttonSupported: Bool) {
        DispatchQueue.main.async {
            self.ledToggleSwitch.isEnabled = ledSupported
            
            if buttonSupported {
                self.buttonStateLabel.text = "Reading...".localized
            }
            if ledSupported {
                self.ledStateLabel.text    = "Reading...".localized
            }
        }
        // Not supoprted device?
        if !ledSupported && !buttonSupported {
            blinkyPeripheral.disconnect()
        }
    }
    
    func blinkyDidDisconnect() {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.barTintColor = UIColor.nordicRed
            self.ledToggleSwitch.onTintColor = UIColor.nordicRed
            self.ledToggleSwitch.isEnabled = false
        }
    }
    
    func ledStateChanged(isOn: Bool) {
        DispatchQueue.main.async {
            if isOn {
                self.ledStateLabel.text = "ON".localized
                self.ledToggleSwitch.setOn(true, animated: true)
            } else {
                self.ledStateLabel.text = "OFF".localized
                self.ledToggleSwitch.setOn(false, animated: true)
            }
        }
    }
    
    func buttonStateChanged(isPressed: Bool) {
        DispatchQueue.main.async {
            if isPressed {
                self.buttonStateLabel.text = "PRESSED".localized
            } else {
                self.buttonStateLabel.text = "RELEASED".localized
            }
            self.buttonTapHapticFeedback()
        }
    }
}
