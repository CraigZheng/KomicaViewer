//
//  UIView+Util.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "UIView+Util.h"
#import "PureLayout.h"

@implementation UIView (Util)


- (void)copyPropertiesFromView:(UIView*)originView {
    // Copy view.frame properties to self.
    self.frame = originView.frame;
    self.autoresizingMask = originView.autoresizingMask;
    self.translatesAutoresizingMaskIntoConstraints =
    originView.translatesAutoresizingMaskIntoConstraints;
    
    // Copy auto layout constraint properties.
    for (NSLayoutConstraint *constraint in originView.constraints)
    {
        id firstItem = constraint.firstItem;
        if (firstItem == originView)
        {
            firstItem = self;
        }
        id secondItem = constraint.secondItem;
        if (secondItem == originView)
        {
            secondItem = self;
        }
        [self addConstraint:
         [NSLayoutConstraint constraintWithItem:firstItem
                                      attribute:constraint.firstAttribute
                                      relatedBy:constraint.relation
                                         toItem:secondItem
                                      attribute:constraint.secondAttribute
                                     multiplier:constraint.multiplier
                                       constant:constraint.constant]];
    }
}

- (void)pinToSuperView {
    if (self.superview) {
        [self autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
}

@end
