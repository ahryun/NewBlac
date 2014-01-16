//
//  PhotoCorners+LifeCycle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/6/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "PhotoCorners+LifeCycle.h"

@implementation PhotoCorners (LifeCycle)

+ (PhotoCorners *)photoCorners:(NSArray *)coordinates withManagedObjectContext:(NSManagedObjectContext *)context
{
    PhotoCorners *photoCorners = nil;
    NSLog(@"%@", coordinates);
    photoCorners = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoCorners" inManagedObjectContext:context];
    photoCorners.bottomLeftxPercent = coordinates[0][0];
    photoCorners.bottomLeftyPercent = coordinates[0][1];
    photoCorners.bottomRightxPercent = coordinates[1][0];
    photoCorners.bottomRightyPercent = coordinates[1][1];
    photoCorners.topLeftxPercent = coordinates[2][0];
    photoCorners.topLeftyPercent = coordinates[2][1];
    photoCorners.topRightxPercent = coordinates[3][0];
    photoCorners.topRightyPercent = coordinates[3][1];
    
    return photoCorners;
}

- (void)photoCorners:(NSArray *)coordinates
{
    self.bottomLeftxPercent = coordinates[0][0];
    self.bottomLeftyPercent = coordinates[0][1];
    self.bottomRightxPercent = coordinates[1][0];
    self.bottomRightyPercent = coordinates[1][1];
    self.topLeftxPercent = coordinates[2][0];
    self.topLeftyPercent = coordinates[2][1];
    self.topRightxPercent = coordinates[3][0];
    self.topRightyPercent = coordinates[3][1];
}

@end
