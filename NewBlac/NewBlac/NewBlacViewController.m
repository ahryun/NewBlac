//
//  blacViewController.m
//  Blac
//
//  Created by Ahryun Moon on 11/20/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "NewBlacViewController.h"
//#import <MobileCoreServices/MobileCoreServices.h>
//#import "Canvas.h"
#import "VideoCreator.h"
#import "VideoPlayView.h"
#import "MotionVideoPlayer.h"

@interface NewBlacViewController ()

@property (strong, nonatomic) VideoCreator *videoCreator;
@property (weak, nonatomic) IBOutlet VideoPlayView *playerView;
@property (strong, nonatomic) MotionVideoPlayer *videoPlayer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;

@end

@implementation NewBlacViewController

static const NSString *PlayerReadyContext;

- (void)setVideo:(Video *)video
{
    _video = video;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Screen width and height in View Did Load is %f x %f\n", self.view.frame.size.width, self.view.frame.size.height);
    [self loadAssetFromVideo];
    UIImage *playButtonImg = [UIImage imageNamed:@"PlayButton"];
    playButtonImg = [playButtonImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.playButton.image = playButtonImg;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.video.photos count] > 1) self.playButton.enabled = YES;
}

- (void)bringUpCamera
{
    // Bring up camera
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.videoPlayer unregisterNotification];
    [self.videoPlayer removeObserver:self forKeyPath:@"playerIsReady" context:&PlayerReadyContext];
    self.videoPlayer.isCancelled = YES;
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        [self cleanUpBeforeReturningToGallery];
    }
}

#pragma mark - Segues
- (IBAction)unwindAddToVideoBuffer:(UIStoryboardSegue *)segue
{
    [self compileVideo];
}

- (IBAction)unwindCancelPhoto:(UIStoryboardSegue *)segue
{
    [self compileVideo];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"I'm in segue\n");
    if ([segue.identifier isEqualToString:@"Ready Camera"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.video];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [segue.destinationViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
        }
    }
}

- (void)cleanUpBeforeReturningToGallery
{
    NSLog(@"I'm in clean up\n");
    if ([self.video.photos count] < 1) {
        [Video removeVideo:self.video inManagedContext:self.managedObjectContext];
    } else {
        // Save the video to child context, which pushes the changes to the parent context on main thread. This will eventually be saved to persistent store when the UIManagedDocument closes.
        NSError *error;
        [self.managedObjectContext save:&error];
    }
}

#pragma mark - Model

- (void)compileVideo
{
    if (self.video && [self.video.photos count] > 0) {
        CGSize size = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height);
        if (!self.videoCreator) self.videoCreator = [[VideoCreator alloc] initWithVideo:self.video withScreenSize:size];
        [self.videoCreator writeImagesToVideo];
        [self loadAssetFromVideo];
    }
}

- (void)loadAssetFromVideo
{
    if (!self.videoPlayer) self.videoPlayer = [[MotionVideoPlayer alloc] init];
    NSURL *videoURL = [NSURL fileURLWithPath:self.video.compFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.video.compFilePath]) {
        [self.videoPlayer loadAssetFromVideo:videoURL];
        [self.videoPlayer addObserver:self forKeyPath:@"playerIsReady" options:0 context:&PlayerReadyContext];
    } else {
        // Video data object exists but no video saved yet
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &PlayerReadyContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setPlayerInLayer:self.videoPlayer.player];
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (IBAction)play:sender
{
    [self.videoPlayer playVideo];
}

- (void)setPlayerInLayer:(AVPlayer *)player
{
    if ((self.videoPlayer.playerIsReady) &&
        ([self.videoPlayer.playerItem status] == AVPlayerItemStatusReadyToPlay)) {
        NSLog(@"Setting the video layer\n");
        [self.playerView setPlayer:player];
        [self.videoPlayer playVideo];
    } else {
        NSLog(@"Video not ready to play\n");
    }
}

@end
