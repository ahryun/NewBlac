//
//  PhotoCorners+LifeCycle.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/6/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "PhotoCorners.h"

@interface PhotoCorners (LifeCycle)

+ (PhotoCorners *)photoCorners:(NSArray *)coordinates;
- (void)setCoordinates:(NSArray *)coordinates;

@end
