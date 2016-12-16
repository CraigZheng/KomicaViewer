//
//  RoundCornerBorderedButton.swift
//  Exellency
//
//  Created by Craig Zheng on 16/05/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import UIKit

@IBDesignable class RoundCornerBorderedButton: UIButton {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        // Unity the tintColor with the current text color.
        tintColor = titleLabel?.textColor
        // Rounded corner border.
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = tintColor.cgColor
    }
    
    // Intrinsic content size must include the title edge insets.
    override var intrinsicContentSize : CGSize {
        var intrinsicSize = super.intrinsicContentSize
        intrinsicSize.width += titleEdgeInsets.left + titleEdgeInsets.right
        intrinsicSize.height += titleEdgeInsets.top + titleEdgeInsets.bottom
        return intrinsicSize
    }
}
