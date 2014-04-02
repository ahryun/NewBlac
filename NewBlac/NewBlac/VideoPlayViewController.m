//
//  VideoPlayViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 2/28/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideoPlayViewController.h"
#import "VideoPlayView.h"
#import "MotionVideoPlayer.h"

@interface VideoPlayViewController ()

@property (nonatomic) BOOL videoIsEmpty;
@property (strong, nonatomic) MotionVideoPlayer *videoPlayer;
//@property (weak, nonatomic) IBOutlet VideoPlayView *playerView;

@end

@implementation VideoPlayViewController

static const NSString *PlayerReadyContext;

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoIsEmpty = YES;
    [self loadAssetFromVideo];
    [self prefersStatusBarHidden];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (!self.videoIsEmpty) {
        [self.videoPlayer unregisterNotification];
        [self.videoPlayer removeObserver:self forKeyPath:@"playerIsReady" context:&PlayerReadyContext];
    }
    self.videoPlayer.isCancelled = YES;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)loadAssetFromVideo
{
    if (!self.videoPlayer) self.videoPlayer = [[MotionVideoPlayer alloc] init];
    NSURL *videoURL = [NSURL fileURLWithPath:self.videoPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.videoPath]) {
        self.videoIsEmpty = NO;
        [self.videoPlayer loadAssetFromVideo:videoURL];
        [self.videoPlayer addObserver:self forKeyPath:@"playerIsReady" options:0 context:&PlayerReadyContext];
    } else {
        // Video data object exists but no video saved yet
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == &PlayerReadyContext) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            [strongSelf setPlayerInLayer:strongSelf.videoPlayer.player];
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (void)setPlayerInLayer:(AVPlayer *)player
{
    if ((self.videoPlayer.playerIsReady) &&
        ([self.videoPlayer.playerItem status] == AVPlayerItemStatusReadyToPlay)) {
        NSLog(@"Setting the video layer\n");
//        [self.playerView setPlayer:player];
        [self.videoPlayer playVideo];
    } else {
        NSLog(@"Video not ready to play\n");
    }
}

- (IBAction)play:sender {
    [self.videoPlayer playVideo];
}

@end
