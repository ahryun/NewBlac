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

+ (CornerCircle *)addCornerWithCoordinate:(NSArray *)coordinate inRect:(CGSize)size;

@end
