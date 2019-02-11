//
//  BlinkyViewController.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 01/12/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth

class BlinkyViewController: UITableViewController, CBCentralManagerDelegate {
    
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
    
    public func setCentralManager(_ manager: CBCentralManager) {
        centralManager = manager
        centralManager.delegate = self
    }
    
    public func setPeripheral(_ peripheral: BlinkyPeripheral) {
        blinkyPeripheral = peripheral
        title = peripheral.advertisedName ?? "Unknown Device".localized
        
        print("Connecting to Blinky device...")
        centralManager.connect(peripheral.basePeripheral, options: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // MARK: - UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard blinkyPeripheral.basePeripheral.state != .connected else {
            // View is coming back from a swipe, everything is already setup
            return
        }
        // This is the first time view appears, setup the subviews and dependencies
        setupDependencies()
    }

    override func viewDidDisappear(_ animated: Bool) {
        blinkyPeripheral.removeLEDCallback()
        blinkyPeripheral.removeButtonCallback()
        
        if blinkyPeripheral.basePeripheral.state == .connected {
            centralManager.cancelPeripheralConnection(blinkyPeripheral.basePeripheral)
        }
        super.viewDidDisappear(animated)
    }

    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            dismiss(animated: true, completion: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == blinkyPeripheral.basePeripheral {
            print("Connected to Blinky")
            blinkyPeripheral.discoverBlinkyServices()
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == blinkyPeripheral.basePeripheral {
            print("Blinky disconnected")
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    // MARK: - Implementation
    
    private func setupDependencies() {
        //This will run on iOS 10 or above
        //and will generate a tap feedback when the button is tapped on the Dev kit.
        prepareHaptics()
        
        //Set default text to Reading ...
        //As soon as peripheral enables notifications the values will be notified
        buttonStateLabel.text = "Reading...".localized
        ledStateLabel.text    = "Reading...".localized
        ledToggleSwitch.isEnabled = false
        
        blinkyPeripheral.setButtonCallback { (isPressed) -> (Void) in
            DispatchQueue.main.async {
                if isPressed {
                    self.buttonStateLabel.text = "PRESSED".localized
                } else {
                    self.buttonStateLabel.text = "RELEASED".localized
                }
                self.buttonTapHapticFeedback()
            }
        }
        
        blinkyPeripheral.setLEDCallback { (isOn) -> (Void) in
            DispatchQueue.main.async {
                if !self.ledToggleSwitch.isEnabled {
                    self.ledToggleSwitch.isEnabled = true
                }
                
                if isOn {
                    self.ledStateLabel.text = "ON".localized
                    if self.ledToggleSwitch.isOn == false {
                        self.ledToggleSwitch.setOn(true, animated: true)
                    }
                } else {
                    self.ledStateLabel.text = "OFF".localized
                    if self.ledToggleSwitch.isOn == true {
                        self.ledToggleSwitch.setOn(false, animated: true)
                    }
                }
            }
        }
    }
    
    private func handleSwitchValueChange(newValue isOn: Bool){
        if isOn {
            blinkyPeripheral.turnOnLED()
            ledStateLabel.text = "ON".localized
        } else {
            blinkyPeripheral.turnOffLED()
            ledStateLabel.text = "OFF".localized
        }
    }

    private func prepareHaptics() {
        if #available(iOS 10.0, *) {
            hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
            (hapticGenerator as? UIImpactFeedbackGenerator)?.prepare()
        }
    }
    
    private func buttonTapHapticFeedback() {
        if #available(iOS 10.0, *) {
            (hapticGenerator as? UIImpactFeedbackGenerator)?.impactOccurred()
        }
    }
}
