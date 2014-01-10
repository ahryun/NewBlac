//
//  CornerCircle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/10/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "CornerCircle.h"

@interface CornerCircle()

@property (nonatomic, strong) UIBezierPath *tapTarget;

@end

@implementation CornerCircle

- (id)init
{
    UIBezierPath *defaultPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
    UIColor *defaultLineColor = [UIColor whiteColor];
    return [self initWithPath:defaultPath lineColor:defaultLineColor];
}

- (id)initWithPath:(UIBezierPath *)path lineColor:(UIColor *)lineColor
{
    self = [super init];
    if (self != nil) {
        _path = path;
        _lineColor = lineColor;
    }
    return self;
}

+ (CornerCircle *)addCornerWithCoordinate:(NSArray *)coordinate
{
    
}

@end
