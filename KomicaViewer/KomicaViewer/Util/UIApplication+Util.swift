//
//  UIApplication+Util.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import Foundation

extension UIApplication {
    
    @objc class var topViewController: UIViewController? {
        var topViewController = UIApplication.shared.keyWindow?.rootViewController
        while topViewController?.presentedViewController != nil {
            topViewController = topViewController?.presentedViewController
        }
        return topViewController
    }
    
    @objc class var appName: String {
        return Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String
    }
}
