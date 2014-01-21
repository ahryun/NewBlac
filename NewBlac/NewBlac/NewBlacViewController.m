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

@end

@implementation NewBlacViewController

static const NSString *ItemStatusContext;

- (IBAction)unwindAddToVideoBuffer:(UIStoryboardSegue *)segue
{
    
    
}

- (IBAction)unwindCancelPhoto:(UIStoryboardSegue *)segue
{
    // Add the photo to the buffer
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Ready Camera"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [segue.destinationViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.video];
        }
    }
}

- (void)useDemoDocument
{
    [[SharedManagedDocument sharedInstance] performWithDocument:^(UIManagedDocument *document){
        self.managedObjectContext = document.managedObjectContext;
        if (!self.video && self.managedObjectContext) {
            // Put the path as nil, if you would Video object to create a random movie file path in Videos folder
            self.video = [Video videoWithPath:nil inManagedObjectContext:self.managedObjectContext];
        }
        [self.addPhoto setEnabled:YES];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self syncUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.video) NSLog(@"Video aspect ratio is %f", [self.video.screenRatio floatValue]);
    if (!self.managedObjectContext) [self useDemoDocument];
    self.playButton.hidden = YES;
    if (self.video && [self.video.photos count] > 0) {
        self.videoCreator = [[VideoCreator alloc] initWithVideo:self.video];
        [self loadAssetFromVideo];
        if ([self.video.photos count] > 1) {
            self.playButton.hidden = NO;
        }
    }
}

- (void)syncUI
{
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    } else {
        self.playButton.enabled = NO;
    }
}

- (void)loadAssetFromVideo
{
    // Play the video
    NSURL *videoURL = [NSURL fileURLWithPath:self.video.compFilePath];
    self.videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    NSString *tracksKey = @"tracks";
    NSLog(@"There are %i tracks in this video", [self.videoAsset.tracks count]);
    [self.videoAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [self.videoAsset statusOfValueForKey:tracksKey error:&error];
            NSLog(@"The AVKeyValueStatus is %i\n", status);
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
