#import "PartialTransparentView.h"
#import <QuartzCore/QuartzCore.h>

@implementation PartialTransparentView
@synthesize rectsArray;
@synthesize backgroundColor;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor*)color andTransparentRects:(NSArray*)rects
{
    backgroundColor = color;
    rectsArray = rects;
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [backgroundColor setFill];
    UIRectFill(rect);
    
    // clear the background in the given rectangles
    for (NSValue *holeRectValue in rectsArray) {
        CGRect holeRect = [holeRectValue CGRectValue];
        CGRect holeRectIntersection = CGRectIntersection( holeRect, rect );
        [[UIColor clearColor] setFill];
        UIRectFill(holeRectIntersection);
    }
    
}


@end