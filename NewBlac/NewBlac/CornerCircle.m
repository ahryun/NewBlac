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

@property (nonatomic) CGFloat circleDiameter;
@property (nonatomic, readwrite) CGPoint centerPoint;

@end

@implementation CornerCircle

- (CGPoint)centerPoint
{
    if (self.path) {
        CGFloat circleRadius = self.circleDiameter / 2;
        _centerPoint = CGPointMake(self.path.bounds.origin.x + circleRadius,
                                       self.path.bounds.origin.y + circleRadius);
    }
    return _centerPoint;
}

- (CGFloat)circleDiameter
{
    return 12.0;
}

- (id)initWithCoordinate:(NSArray *)coordinate inRect:(CGSize)size
{
    self = [super init];
    CGFloat circleRadius = self.circleDiameter / 2;
    if (self != nil) {
        self.path = [UIBezierPath bezierPathWithOvalInRect:
                 CGRectMake((CGFloat)[coordinate[0] floatValue] * size.width - circleRadius,
                            (CGFloat)[coordinate[1] floatValue] * size.height - circleRadius,
                            self.circleDiameter, self.circleDiameter)];
        UIBezierPath *whiteCircle = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.path.bounds, -3.f, -3.f)];
        [self.path appendPath:whiteCircle];
        
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
    UIBezierPath *tapTarget = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(path.bounds.origin.x - (self.circleDiameter * 2), path.bounds.origin.y - (self.circleDiameter * 2), self.circleDiameter * 5, self.circleDiameter * 5)];
    
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
//    return CGRectInset(self.tapTarget.bounds, -(self.tapTarget.lineWidth + 1.0f), -(self.tapTarget.lineWidth + 1.0f));
}

#pragma mark - Modifying Shapes

- (void)moveBy:(CGPoint)delta
{
    CGAffineTransform transform = CGAffineTransformMakeTranslation(delta.x, delta.y);
    [self.path applyTransform:transform];
    [self.tapTarget applyTransform:transform];
}


@end
