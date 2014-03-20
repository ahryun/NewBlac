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

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;
- (void)addVideo:(Video *)video;
- (void)updateVideo:(Video *)video;
- (void)removeVideo:(Video *)video;

@end
