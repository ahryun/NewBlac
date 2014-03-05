//
//  MotionVideoPlayer.m
//  NewBlac
//
//  Created by Ahryun Moon on 2/23/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "MotionVideoPlayer.h"

@interface MotionVideoPlayer()

@property (strong, nonatomic) AVURLAsset *videoAsset;

@end

@implementation MotionVideoPlayer

static const NSString *ItemStatusContext;
static const NSString *ItemRateContext;

- (void)loadAssetFromVideo:(NSURL *)videoURL
{
    // Play the video
    self.playerIsReady = NO;
    self.isPlaying = NO;
    self.videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    NSLog(@"Video URL is %@\n", videoURL);
    NSLog(@"There are %lu tracks in this video", (unsigned long)[self.videoAsset.tracks count]);
    self.isCancelled = NO;
    
    NSString *tracksKey = @"tracks";
    [self.videoAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isCancelled) {
                NSError *error;
                AVKeyValueStatus status = [self.videoAsset statusOfValueForKey:tracksKey error:&error];
                NSLog(@"The AVKeyValueStatus is %li\n", (long)status);
                if (status == AVKeyValueStatusLoaded) {
                    self.playerItem = [AVPlayerItem playerItemWithAsset:self.videoAsset];
                    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                    [self registerNotification];
                } else {
                    // You should deal with the error appropriately.
                    NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                }
            } else {
                return;
            }
        });
    }];
}

- (void)registerNotification
{
    [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
    [self.player addObserver:self forKeyPath:@"rate" options:0 context:&ItemRateContext];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Context is %ld\n", (long)[self.player.currentItem status]);
            if ([self.playerItem status] == AVPlayerItemStatusReadyToPlay) {
                self.duration = CMTimeGetSeconds(self.playerItem.duration);
                self.playerIsReady = YES;
            } else {
                self.playerIsReady = NO;
            }
        });
        return;
    } else if (context == &ItemRateContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.player.rate == 0) { //stopped
                self.isPlaying = NO;
            } else {
                self.isPlaying = YES;
            }
        });
    }
}

- (void)replacePlayerItem:(NSURL *)videoURL
{
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:videoURL];
    [self.player replaceCurrentItemWithPlayerItem:item];
}

- (void)playVideo
{
    if (!self.isCancelled) {
        [self.player play];
        self.isPlaying = YES;
    }
}

- (void)pauseVideo
{
    [self.player pause];
    self.isPlaying = NO;
}

- (void)rewindVideo
{
    [self.player seekToTime:kCMTimeZero];
}

- (void)unregisterNotification
{
    [self.playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
    [self.player removeObserver:self forKeyPath:@"rate" context:&ItemRateContext];
}

@end
