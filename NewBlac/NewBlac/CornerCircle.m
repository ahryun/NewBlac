//
//  CornerCircle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/10/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//
//  Only define the geometry of the corner circles
//  Corlors and other attributes will be set in the view

#import "CornerCircle.h"

@interface CornerCircle()

@property (nonatomic) float circleDiameter;

@end

@implementation CornerCircle

- (float)circleDiameter
{
    return 10.0;
}

- (id)initWithCoordinate:(NSArray *)coordinate inRect:(CGSize)size
{
    self = [super init];
    float circleRadius = self.circleDiameter / 2;
    if (self != nil) {
        self.path = [UIBezierPath bezierPathWithOvalInRect:
                 CGRectMake([coordinate[0] floatValue] * size.width - circleRadius,
                            [coordinate[1] floatValue] * size.height - circleRadius,
                            self.circleDiameter, self.circleDiameter)];
        self.tapTarget = [self tapTargetForPath:self.path];
    }
    return self;
}

+ (CornerCircle *)addCornerWithCoordinate:(NSArray *)coordinate inRect:(CGSize)size
{
    return [[self alloc] initWithCoordinate:coordinate inRect:(CGSize)size];
}

#pragma mark - Hit Testing

- (UIBezierPath *)tapTargetForPath:(UIBezierPath *)path
{
    if (path == nil) {
        return nil;
    }
    
    CGPathRef tapTargetPath = CGPathCreateCopyByStrokingPath(path.CGPath, NULL, fmaxf(35.0f, path.lineWidth), path.lineCapStyle, path.lineJoinStyle, path.miterLimit);
    
    if (tapTargetPath == NULL) {
        return nil;
    }
    
    UIBezierPath *tapTarget = [UIBezierPath bezierPathWithCGPath:tapTargetPath];
    CGPathRelease(tapTargetPath);
    return tapTarget;
}

- (BOOL)containsPoint:(CGPoint)point
{
    return [self.tapTarget containsPoint:point];
}

#pragma mark - Bounds

- (CGRect)totalBounds
{
    if (self.path == nil) {
        return CGRectZero;
    }
    
    return CGRectInset(self.path.bounds, -(self.path.lineWidth + 1.0f), -(self.path.lineWidth + 1.0f));
}

@end
