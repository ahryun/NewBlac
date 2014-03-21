//
//  ParseSyncer.h
//  NewBlac
//
//  Created by Ahryun Moon on 3/19/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Video+LifeCycle.h"

@interface ParseSyncer : NSObject

// Add a video on Parse
+ (void)addVideo:(Video *)video inContext:(NSManagedObjectContext *)context;
//+ (void)updateVideo:(Video *)video;

// If anything changed about the video, it gets synced on Parse
+ (void)updateVideosInContext:(NSManagedObjectContext *)context;

// Remove one video on Parse as the user deletes it on her device
+ (void)removeVideo:(Video *)video;

// Clean up Parse DB
+ (void)removeVideosInContext:(NSManagedObjectContext *)context;

@end
