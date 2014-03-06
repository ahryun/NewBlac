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
    UIColor *fillColor = [self.delegate fillColorInView:self];
    UIColor *strokeColor = [UIColor whiteColor];
    if (noCorners) {
        for (NSUInteger index = 0; index < noCorners; index++) {
            UIBezierPath *corner = [self.delegate drawPathInView:self atIndex:index];
            UIBezierPath *whiteCircle = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(corner.bounds, -3.f, -3.f)];
            [fillColor setFill];
            [corner fill];
            [strokeColor setStroke];
            [corner stroke];
            [whiteCircle stroke];
        }
    }
}

@synthesize delegate;

@end
