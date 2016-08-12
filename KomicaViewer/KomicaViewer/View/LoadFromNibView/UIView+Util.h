//
//  UIView+Util.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Util)
- (void)copyPropertiesFromView:(UIView*)originView;
- (void)pinToSuperView;
@end
