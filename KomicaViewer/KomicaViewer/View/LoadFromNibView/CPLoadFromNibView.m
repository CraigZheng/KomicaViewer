//
//  CPLoadFromNibView.m
//  CashByOptusPhone
//
//  Created by Craig on 31/08/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import "CPLoadFromNibView.h"
#import "UIView+Util.h"

@implementation CPLoadFromNibView

// Technique copies from http://cocoanuts.mobi/2014/03/26/reusable/ and ajusted to suit our needs.
- (instancetype)awakeAfterUsingCoder:(NSCoder *)aDecoder {
    if (![self.subviews count]) {
        // If self has no subviews - which means it just been loaded - replace it with a custom view load from NIB.
        id loadedView = [self.class viewFromNib];
        [(UIView *)loadedView copyPropertiesFromView:self];
        
        // Point self to the view just loaded from NIB.
        self = loadedView;
    }
    return self;
}

+ (instancetype)viewFromNib {
    return [[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil].firstObject;
}

@end
