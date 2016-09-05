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
    
    class func showMessage(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            if let rootView = UIApplication.topViewController?.view {
                let hud = MBProgressHUD.showHUDAddedTo(rootView, animated:true)
                // Set the annular determinate mode to show task progress.
                hud.mode = .Text
                
                hud.detailsLabelText = message
                hud.userInteractionEnabled = false
                // Move to bottm center.
                hud.xOffset = 0
                hud.yOffset = Float(CGRectGetHeight(UIScreen.mainScreen().bounds) / 2 - 60)
                hud.hide(true, afterDelay: 3.0)
            }
        }
    }

}
