//
//  CornerDetectionView.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/7/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "CornerDetectionView.h"

@implementation CornerDetectionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib
{
    if (self) {

    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [self.delegate displayCorners];
    NSLog(@"%@\n", self.bottomLeftCorner);
    NSLog(@"%@\n", self.bottomRightCorner);
    NSLog(@"%@\n", self.topLeftCorner);
    NSLog(@"%@\n", self.topRightCorner);
    
    UIBezierPath *bottomLeftCornerCircle = [UIBezierPath bezierPathWithOvalInRect:
                                            CGRectMake([self.bottomLeftCorner[0] floatValue] * self.frame.size.width,
                                                       [self.bottomLeftCorner[1] floatValue] * self.frame.size.height,
                                                       10.0, 10.0)];
    UIBezierPath *bottomRightCornerCircle = [UIBezierPath bezierPathWithOvalInRect:
                                             CGRectMake([self.bottomRightCorner[0] floatValue] * self.frame.size.width,
                                                        [self.bottomRightCorner[1] floatValue] * self.frame.size.height,
                                                        10.0, 10.0)];
    UIBezierPath *topLeftCornerCircle = [UIBezierPath bezierPathWithOvalInRect:
                                         CGRectMake([self.topLeftCorner[0] floatValue] * self.frame.size.width,
                                                    [self.topLeftCorner[1] floatValue] * self.frame.size.height,
                                                    10.0, 10.0)];
    UIBezierPath *topRightCornerCircle = [UIBezierPath bezierPathWithOvalInRect:
                                          CGRectMake([self.topRightCorner[0] floatValue] * self.frame.size.width,
                                                     [self.topRightCorner[1] floatValue] * self.frame.size.height,
                                                     10.0, 10.0)];
    [[UIColor blueColor] setFill];
    [bottomLeftCornerCircle fill];
    [bottomRightCornerCircle fill];
    [topLeftCornerCircle fill];
    [topRightCornerCircle fill];
    
}

@synthesize delegate;

@end
