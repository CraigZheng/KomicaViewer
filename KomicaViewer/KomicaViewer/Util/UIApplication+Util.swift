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
        let topViewController = UIApplication.sharedApplication().keyWindow?.rootViewController?.presentedViewController ?? UIApplication.sharedApplication().keyWindow?.rootViewController
        return topViewController
    }
}