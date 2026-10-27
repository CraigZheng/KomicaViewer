//
//  ProgressHUD.swift
//  Exellency
//
//  Created by Craig Zheng on 7/08/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import UIKit

import MBProgressHUD

class ProgressHUD: MBProgressHUD {
    
    class func showMessage(_ message: String) {
        DispatchQueue.main.async {
            if let rootView = UIApplication.topViewController?.view {
                let hud = MBProgressHUD.showAdded(to: rootView, animated: true)
                hud.mode = .text
                hud.detailsLabel.text = message
                hud.isUserInteractionEnabled = false
                hud.offset = CGPoint(x: 0, y: UIScreen.main.bounds.height / 2 - 60)
                hud.hide(animated: true, afterDelay: 2.0)
            }
        }
    }

}
