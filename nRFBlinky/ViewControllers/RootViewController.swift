//
//  RootViewController.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 28/11/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit

class RootViewController: UINavigationController, UINavigationControllerDelegate {
    @IBOutlet var wirelessByNordicView: UIView!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate = self
        if !view.subviews.contains(wirelessByNordicView) {
            view.addSubview(wirelessByNordicView)
            wirelessByNordicView.frame = CGRect(x: 0, y: (view.frame.height - wirelessByNordicView.frame.size.height), width: view.frame.width, height: wirelessByNordicView.frame.height)
            view.bringSubview(toFront: wirelessByNordicView)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        UIView.animate(withDuration: 0.05) {
            self.wirelessByNordicView.alpha = 0
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        UIView.animate(withDuration: 0.05) {
            self.wirelessByNordicView.alpha = 1
        }
    }
}
