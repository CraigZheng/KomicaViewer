//
//  UIColor+RGB.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 12/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import Foundation

extension UIColor {
    @objc static func colorWithRedValue(_ redValue: Int, greenValue: Int, blueValue: Int, alpha: Double) -> UIColor {
        return UIColor(red: CGFloat(redValue)/255.0, green: CGFloat(greenValue)/255.0, blue: CGFloat(blueValue)/255.0, alpha: CGFloat(alpha))
    }
}
