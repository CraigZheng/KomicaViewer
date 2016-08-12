//
//  CPLoadFromNibView.h
//  CashByOptusPhone
//
//  Created by Craig on 31/08/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 The purpose of this class is to combine storyboard and custom view in nib file. All subclass of this view will be declared in a storyboard but implemented in a nib file. 
 +[CPLoadFromNibView viewFromNib] should be overrided by subclass to indicate the proper NIB file to load.
 */
@interface CPLoadFromNibView : UIView

+ (instancetype)viewFromNib;

@end
