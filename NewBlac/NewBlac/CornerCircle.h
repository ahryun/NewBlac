//
//  CornerCircle.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/10/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CornerCircle : NSObject

@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, assign, readonly) CGRect totalBounds;
@property (nonatomic, strong) UIBezierPath *tapTarget;
@property (nonatomic, assign, readonly) CGPoint centerPoint;

+ (CornerCircle *)addCornerWithCoordinate:(NSArray *)coordinate inRect:(CGSize)size;
- (BOOL)containsPoint:(CGPoint)point;
- (void)moveBy:(CGPoint)delta;
- (CGPoint)centerPoint;

@end
