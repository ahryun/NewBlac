//
//  blacViewController.m
//  Blac
//
//  Created by Ahryun Moon on 11/20/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "NewBlacViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Canvas.h"
#import "VideoCreator.h"
#import "VideoPlayView.h"

@interface NewBlacViewController ()

@property (weak, nonatomic) IBOutlet UIButton *addPhoto;
@property (strong, nonatomic) VideoCreator *videoCreator;
@property (strong, nonatomic) AVURLAsset *videoAsset;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;
@property (weak, nonatomic) IBOutlet VideoPlayView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) BOOL isCancelled;

@end

@implementation NewBlacViewController

static const NSString *ItemStatusContext;

#pragma mark - Segues
- (IBAction)unwindAddToVideoBuffer:(UIStoryboardSegue *)segue
{
    // Nothing needs to be done
}

- (IBAction)unwindCancelPhoto:(UIStoryboardSegue *)segue
{
    // Add the photo to the buffer
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Ready Camera"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.video];
        }
    }
}

#pragma mark - View Lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"Screen width and height in View Will Appear is %f x %f\n", self.view.frame.size.width, self.view.frame.size.height);
    
    self.playButton.hidden = YES;
    if (self.video && [self.video.photos count] > 0) {
        if ([self.video.photos count] > 1) self.playButton.hidden = NO;
        CGSize size = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height);
        if (!self.videoCreator) self.videoCreator = [[VideoCreator alloc] initWithVideo:self.video withScreenSize:size];
        [self.videoCreator writeImagesToVideo];
        [self loadAssetFromVideo];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Screen width and height in View Did Load is %f x %f\n", self.view.frame.size.width, self.view.frame.size.height);
    [self syncUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.isCancelled = YES;
}

#pragma mark - UI
- (void)syncUI
{
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    } else {
        self.playButton.enabled = NO;
    }
}

#pragma mark - Model
- (void)loadAssetFromVideo
{
    // Play the video
    NSURL *videoURL = [NSURL fileURLWithPath:self.video.compFilePath];
    self.videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    NSString *tracksKey = @"tracks";
    NSLog(@"There are %lu tracks in this video", (unsigned long)[self.videoAsset.tracks count]);
    self.isCancelled = NO;
    [self.videoAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isCancelled) {
                NSError *error;
                AVKeyValueStatus status = [self.videoAsset statusOfValueForKey:tracksKey error:&error];
                NSLog(@"The AVKeyValueStatus is %li\n", (long)status);
                if (status == AVKeyValueStatusLoaded) {
                    self.playerItem = [AVPlayerItem playerItemWithAsset:self.videoAsset];
                    [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(playerItemDidReachEnd:)
                                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                                               object:self.playerItem];
                    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                    [self.playerView setPlayer:self.player];
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

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self.player seekToTime:kCMTimeZero];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
               [self syncUI];
           });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (IBAction)play:sender
{
    [self.player play];
}

@end
