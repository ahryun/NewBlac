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
@property (nonatomic, readwrite) CGPoint centerPoint;

@end

@implementation CornerCircle

- (CGPoint)centerPoint
{
    if (self.path) {
        float circleRadius = self.circleDiameter / 2;
        _centerPoint = CGPointMake(self.path.bounds.origin.x + circleRadius,
                                       self.path.bounds.origin.y + circleRadius);
    }
    return _centerPoint;
}

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
    
    // Make the hit detection area 3 times bigger for people with fat fingers
    UIBezierPath *tapTarget = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(path.bounds.origin.x - self.circleDiameter, path.bounds.origin.y - self.circleDiameter, self.circleDiameter * 3, self.circleDiameter * 3)];
    
    if (tapTarget == NULL) {
        return nil;
    }
    
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

#pragma mark - Modifying Shapes

- (void)moveBy:(CGPoint)delta
{
    CGAffineTransform transform = CGAffineTransformMakeTranslation(delta.x, delta.y);
    [self.path applyTransform:transform];
    [self.tapTarget applyTransform:transform];
}


@end
