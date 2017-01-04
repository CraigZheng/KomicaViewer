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
                let hud = MBProgressHUD.showAdded(to: rootView, animated:true)
                // Set the annular determinate mode to show task progress.
                hud?.mode = .text
                
                hud?.detailsLabelText = message
                hud?.isUserInteractionEnabled = false
                // Move to bottm center.
                hud?.xOffset = 0
                hud?.yOffset = Float(UIScreen.main.bounds.height / 2 - 60)
                hud?.hide(true, afterDelay: 2.0)
            }
        }
    }

}
