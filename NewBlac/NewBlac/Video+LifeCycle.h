//
//  Video+LifeCycle.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/16/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Video.h"

@interface Video (LifeCycle)

#define MAX_PHOTO_COUNT_PER_VIDEO 75

+ (Video *)videoWithPath:(NSString *)path inManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)removeVideo:(Video *)video inManagedContext:(NSManagedObjectContext *)context;
+ (void)removeVideosInManagedContext:(NSManagedObjectContext *)context;

- (NSArray *)imagesArrayInOrder;
- (void)updateAPhotoIndexInVideo:(Photo *)photo atEnd:(BOOL)atEnd;
- (void)updateAllPhotoIndexInVideo;
- (BOOL)addPhotosObjectWithAuthentification:(Photo *)photo;

@end
