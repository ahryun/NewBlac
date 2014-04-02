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

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    NSUInteger noCorners = [self.delegate numberOfCornersInView:self];
    UIColor *fillColor = [self.delegate fillColorInView:self];
    UIColor *strokeColor = [UIColor whiteColor];
    if (noCorners) {
        for (NSUInteger index = 0; index < noCorners; index++) {
            UIBezierPath *corner = [self.delegate drawPathInView:self atIndex:index];
//            UIBezierPath *tapTarget = [self.delegate drawTapTargetInView:self atIndex:index];
            
            [fillColor setFill];
            [corner fill];
//            [tapTarget fill];
            [strokeColor setStroke];
            [corner stroke];
        }
    }
}

@synthesize delegate;

@end
