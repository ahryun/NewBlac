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
    
    photoCorners = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoCorners" inManagedObjectContext:context];
    photoCorners.bottomLeftx = coordinates[0][0];
    photoCorners.bottomLefty = coordinates[0][1];
    photoCorners.bottomRightx = coordinates[1][0];
    photoCorners.bottomRighty = coordinates[1][1];
    photoCorners.topLeftx = coordinates[2][0];
    photoCorners.topLeftx = coordinates[2][1];
    photoCorners.topRightx = coordinates[3][0];
    photoCorners.topRighty = coordinates[3][1];
    
    return photoCorners;
}

@end
