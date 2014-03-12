//
//  VideoCreator.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/18/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Video+LifeCycle.h"

@interface VideoCreator : NSObject

@property (nonatomic, strong) Video *video;
@property (nonatomic) BOOL videoDoneCreating;
@property (nonatomic) int numberOfFramesInLastCompiledVideo;

- (id)initWithVideo:(Video *)video withScreenSize:(CGSize)size;
- (void)writeImagesToVideo;

@end
