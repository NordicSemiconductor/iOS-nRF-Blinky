//
//  RootViewController.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 28/11/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit

class RootViewController: UINavigationController {
    
    // Make sure the status bar is light in the app.
    // The default is set to black, as this one is used in the Launch Screen.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
