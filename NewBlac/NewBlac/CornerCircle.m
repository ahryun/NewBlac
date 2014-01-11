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
@property (nonatomic, strong) UIBezierPath *tapTarget;

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
    }
    return self;
}

+ (CornerCircle *)addCornerWithCoordinate:(NSArray *)coordinate inRect:(CGSize)size
{
    return [[self alloc] initWithCoordinate:coordinate inRect:(CGSize)size];
}

@end
