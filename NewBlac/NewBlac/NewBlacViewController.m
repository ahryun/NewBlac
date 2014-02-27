//
//  blacViewController.m
//  Blac
//
//  Created by Ahryun Moon on 11/20/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "NewBlacViewController.h"
#import "VideoCreator.h"
#import "VideoPlayView.h"
#import "MotionVideoPlayer.h"

@interface NewBlacViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) VideoCreator *videoCreator;
@property (weak, nonatomic) IBOutlet VideoPlayView *playerView;
@property (strong, nonatomic) MotionVideoPlayer *videoPlayer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *framesPerSecond;
@property (strong, nonatomic) UIPickerView *pickerView;
@property (strong, nonatomic) UIView *snapshotView;
@property (nonatomic) BOOL videoIsEmpty;

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
    self.videoIsEmpty = YES;
    [self loadAssetFromVideo];
    UIImage *playButtonImg = [[UIImage imageNamed:@"PlayButton"]
                              imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.playButton.image = playButtonImg;
    [self.framesPerSecond setTitle:[NSString stringWithFormat:@"%d FPS", [self.video.framesPerSecond integerValue]]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.video.photos count] > 0) self.playButton.enabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (!self.videoIsEmpty) {
        [self.videoPlayer unregisterNotification];
        [self.videoPlayer removeObserver:self forKeyPath:@"playerIsReady" context:&PlayerReadyContext];
    }
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) [self cleanUpBeforeReturningToGallery];
    self.videoPlayer.isCancelled = YES;
}

#pragma mark - Segues
- (IBAction)unwindAddToVideoBuffer:(UIStoryboardSegue *)segue
{
    [self compileVideo];
}

- (IBAction)unwindCancelPhoto:(UIStoryboardSegue *)segue
{
//    [self compileVideo];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setPlayerInLayer:self.videoPlayer.player];
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
        [self.playerView setPlayer:player];
        [self.videoPlayer playVideo];
    } else {
        NSLog(@"Video not ready to play\n");
    }
}

- (IBAction)play:sender {
    [self.videoPlayer playVideo];
}

#pragma mark - UIPickerView
- (IBAction)chooseFramesPerSecond:(UIBarButtonItem *)sender
{
    [self.videoPlayer pauseVideo];
    
    [self prepareFramesPerSecondPickerView];
    
    // Animation to bring it up
    [UIView animateWithDuration:1 animations:^{
        self.snapshotView.frame = CGRectOffset(self.snapshotView.frame, 0, -CGRectGetHeight(self.pickerView.frame));
        self.pickerView.frame = CGRectOffset(self.pickerView.frame, 0, -CGRectGetHeight(self.pickerView.frame));
    }];
}

- (void)prepareFramesPerSecondPickerView
{
    // Create snapshot
    UIView *snapShot = [self.navigationController.view resizableSnapshotViewFromRect:self.navigationController.view.frame afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    snapShot.frame = self.navigationController.view.frame;
    [self.navigationController.view addSubview:snapShot];
    self.snapshotView = snapShot;
    [self.snapshotView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removePickerView)]];
    
    // Create picker view
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    pickerView.showsSelectionIndicator = YES;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    pickerView.backgroundColor = [UIColor whiteColor];
    CGRect pickerViewFrame = CGRectMake(0, CGRectGetHeight(self.navigationController.view.frame),
                                        CGRectGetWidth(pickerView.frame),
                                        CGRectGetHeight(pickerView.frame));
    [pickerView setFrame:pickerViewFrame];
    [pickerView selectRow:[self.video.framesPerSecond integerValue]-1 inComponent:0 animated:NO];
    [self.navigationController.view addSubview:pickerView];
    self.pickerView = pickerView;
}

- (void)removePickerView
{
    // Animation to bring it up
    [UIView animateWithDuration:1 animations:^{
        self.snapshotView.frame = CGRectOffset(self.snapshotView.frame, 0, CGRectGetHeight(self.pickerView.frame));
        self.pickerView.frame = CGRectOffset(self.pickerView.frame, 0, CGRectGetHeight(self.pickerView.frame));
    } completion:^(BOOL finished) {
        [self.snapshotView removeFromSuperview];
        [self.pickerView removeFromSuperview];
        [self.videoPlayer playVideo];
    }];
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 3;
}

#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *item = [NSString stringWithFormat:@"%d Frames Per Second", row+1];
    return item;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // perform some action
    NSNumber *framesPerSecond = [NSNumber numberWithInteger:row + 1];
    [self.video setFramesPerSecond:framesPerSecond];
    [self.framesPerSecond setTitle:[NSString stringWithFormat:@"%d FPS", [framesPerSecond integerValue]]];
}

@end
