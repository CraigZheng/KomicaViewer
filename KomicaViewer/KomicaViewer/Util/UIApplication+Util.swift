//
//  UIApplication+Util.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import Foundation

extension UIApplication {
    
    class var topViewController: UIViewController? {
        var topViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        while topViewController?.presentedViewController != nil {
            topViewController = topViewController?.presentedViewController
        }
        return topViewController
    }
    
    class var appName: String {
        return NSBundle.mainBundle().infoDictionary!["CFBundleDisplayName"] as! String
    }
}