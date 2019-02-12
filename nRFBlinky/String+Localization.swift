//
//  String+Localization.swift
//  nRFBlinky
//
//  Created by Aleksander Nowakowski on 08/02/2019.
//  Copyright © 2019 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation

extension String {
    
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    func localized(withComment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
    }
    
}
