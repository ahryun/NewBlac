//
//  Video+LifeCycle.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/16/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Video.h"
#import "Strings.h"

@interface Video (LifeCycle)

+ (Video *)videoWithPath:(NSString *)path;
+ (void)removeVideo:(Video *)video;
+ (void)removeVideos;

- (NSArray *)imagesArrayInOrder;
- (void)updateAPhotoIndexInVideo:(Photo *)photo atEnd:(BOOL)atEnd;
- (void)updateAllPhotoIndexInVideo;
- (BOOL)addPhotosObjectWithAuthentification:(Photo *)photo;

@end
