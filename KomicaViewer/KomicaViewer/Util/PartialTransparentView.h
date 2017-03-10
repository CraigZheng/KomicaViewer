//
//  PartialTransparentView.h
//  CustomImageBoardViewer
//
//  Created by Craig on 31/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PartialTransparentView : UIView
@property NSArray *rectsArray;
@property UIColor *backgroundColor;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor*)color andTransparentRects:(NSArray*)rects;


@end
