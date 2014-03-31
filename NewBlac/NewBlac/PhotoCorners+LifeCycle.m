//
//  PhotoCorners+LifeCycle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/6/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "PhotoCorners+LifeCycle.h"

@implementation PhotoCorners (LifeCycle)

+ (PhotoCorners *)photoCorners:(NSArray *)coordinates
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    PhotoCorners *photoCorners = [PhotoCorners MR_createInContext:context];
    NSLog(@"%@", coordinates);
    photoCorners.bottomLeftxPercent = coordinates[0][0];
    photoCorners.bottomLeftyPercent = coordinates[0][1];
    photoCorners.bottomRightxPercent = coordinates[1][0];
    photoCorners.bottomRightyPercent = coordinates[1][1];
    photoCorners.topLeftxPercent = coordinates[2][0];
    photoCorners.topLeftyPercent = coordinates[2][1];
    photoCorners.topRightxPercent = coordinates[3][0];
    photoCorners.topRightyPercent = coordinates[3][1];
    
    [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (error) NSLog(@"An error occurred while trying to save context %@", error);
    }];
    
    return photoCorners;
}

- (void)setCoordinates:(NSArray *)coordinates
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
