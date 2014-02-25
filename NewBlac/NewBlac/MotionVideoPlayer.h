//
//  MotionVideoPlayer.h
//  NewBlac
//
//  Created by Ahryun Moon on 2/23/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MotionVideoPlayer : NSObject

@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;
@property (nonatomic) BOOL isCancelled;
@property (nonatomic) BOOL playerIsReady;

- (void)loadAssetFromVideo:(NSURL *)videoURL;
- (void)replacePlayerItem:(NSURL *)videoURL;
- (void)playVideo;
- (void)pauseVideo;
- (void)replayVideo;
- (void)unregisterNotification;

@end