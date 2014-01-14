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
        self.opaque = NO;
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)awakeFromNib
{
    if (self) {
        self.opaque = NO;
        [self setBackgroundColor:[UIColor clearColor]];
    }
}

- (void)reloadData
{
    [self setNeedsDisplay];
}

- (void)reloadDataInRect:(CGRect)rect
{
    [self setNeedsDisplayInRect:rect];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    NSUInteger noCorners = [self.delegate numberOfCornersInView:self];
    UIColor *color = [self.delegate fillColorInView:self];
    if (noCorners) {
        for (NSUInteger index = 0; index < noCorners; index++) {
            UIBezierPath *corner = [self.delegate drawPathInView:self atIndex:index];
//            NSLog(@"Corner coordinate is %f, %f\n", corner.currentPoint.x, corner.currentPoint.y);
            [color setFill];
            [corner fill];
        }
    }
    
//    UIColor *tapColor = [self.delegate fillTapColorInView:self];
//    if (noCorners) {
//        for (NSUInteger index = 0; index < noCorners; index++) {
//            UIBezierPath *corner = [self.delegate drawTaptargetInView:self atIndex:index];
////            NSLog(@"Corner coordinate is %f, %f\n", corner.currentPoint.x, corner.currentPoint.y);
//            [tapColor setFill];
//            [corner fill];
//        }
//    }
}

@synthesize delegate;

@end
