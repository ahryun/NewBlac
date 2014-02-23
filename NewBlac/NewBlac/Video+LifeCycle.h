//
//  Video+LifeCycle.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/16/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Video.h"

@interface Video (LifeCycle)

+ (Video *)videoWithPath:(NSString *)path inManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)removeVideo:(Video *)video inManagedContext:(NSManagedObjectContext *)context;
+ (void)removeVideosInManagedContext:(NSManagedObjectContext *)context;

- (NSArray *)imagesArrayInOrder;

// Support functions
+ (NSString *)getRandomFilePath;

@end
