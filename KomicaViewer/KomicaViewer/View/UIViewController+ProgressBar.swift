//
//  UIViewController+ProgressBar.swift
//  Exellency
//
//  Created by Craig Zheng on 5/04/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import Foundation

extension UIViewController {
    @objc func showLoading() {
        hideLoading()
        DLog("showLoading()")
        let activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.startAnimating()
        let indicatorBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        if var rightBarButtonItems = navigationItem.rightBarButtonItems {
            rightBarButtonItems.append(indicatorBarButtonItem)
            navigationItem.rightBarButtonItems = rightBarButtonItems
        } else {
            navigationItem.rightBarButtonItem = indicatorBarButtonItem
        }
    }
    
    @objc func hideLoading() {
        DLog("hideLoading()")
        if let rightBarButtonItems = navigationItem.rightBarButtonItems {
            var BarButtonItemsWithoutActivityIndicator = rightBarButtonItems
            for button in rightBarButtonItems {
                if let customView = button.customView {
                    if customView.isKind(of: UIActivityIndicatorView.self) {
                        // Remove the bar button with an activity indicator as the custom view.
                        BarButtonItemsWithoutActivityIndicator.removeObject(button)
                    }
                }
            }
            // At the end, if the count of the array without activity indicator is different than the original array,
            // then assign the modified array to the menu bar.
            if BarButtonItemsWithoutActivityIndicator.count != rightBarButtonItems.count {
                navigationItem.rightBarButtonItems = BarButtonItemsWithoutActivityIndicator
            }
        }
    }
}

extension RangeReplaceableCollection where Iterator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(_ object : Iterator.Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
}
