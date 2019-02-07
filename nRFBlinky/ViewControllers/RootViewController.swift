//
//  RootViewController.swift
//  nRFBlinky
//
//  Created by Mostafa Berg on 28/11/2017.
//  Copyright © 2017 Nordic Semiconductor ASA. All rights reserved.
//

import UIKit

class RootViewController: UINavigationController {
    @IBOutlet var wirelessByNordicView: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !view.subviews.contains(wirelessByNordicView) {
            view.addSubview(wirelessByNordicView)
            wirelessByNordicView.frame = CGRect(x: 0, y: (view.frame.height - wirelessByNordicView.frame.size.height), width: view.frame.width, height: wirelessByNordicView.frame.height)
            view.bringSubviewToFront(wirelessByNordicView)
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.wirelessByNordicView.alpha = 0
        if view.subviews.contains(wirelessByNordicView) {
            coordinator.animateAlongsideTransition(in: self.view, animation: { (context) in
                self.wirelessByNordicView.alpha = 0
                self.wirelessByNordicView.frame = CGRect(x: 0,
                                                         y: (context.containerView.frame.size.height - 27),
                                                         width: context.containerView.frame.size.width,
                                                         height: 27)
            }, completion: { (context) in
                UIView.animate(withDuration: 0.5, animations: {
                    self.wirelessByNordicView.alpha = 1
                })
            })
        }
    }
}
