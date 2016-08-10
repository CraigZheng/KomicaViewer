//
//  UIView+Util.swift
//  Exellency
//
//  Created by Craig Zheng on 28/05/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import UIKit

extension UIView {
    func superCell()->UITableViewCell? {
        var cell: UIView? = self
        while cell != nil && !(cell is UITableViewCell) {
            cell = cell!.superview
        }
        return cell as? UITableViewCell ?? nil
    }
    
    func superCollectionViewCell()->UICollectionViewCell? {
        var cell: UIView? = self
        while cell != nil && !(cell is UICollectionViewCell) {
            cell = cell!.superview
        }
        return cell as? UICollectionViewCell ?? nil
    }
    
}