//
//  FullScreenMovieViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/1/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "FullScreenMovieViewController.h"
#import "MotionVideoPlayer.h"
#import "VideoPlayView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface FullScreenMovieViewController ()

@property (nonatomic, strong) MotionVideoPlayer *moviePlayerController;
@property (nonatomic, strong) VideoPlayView *videoPlayView;
@property (weak, nonatomic) IBOutlet UIView *customControlsView;
@property (weak, nonatomic) IBOutlet UINavigationBar *topBar;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (strong, nonatomic) UIView *bottomBar;
@property (strong, nonatomic) UIButton *moviePlayButton;
@property (strong, nonatomic) UILabel *moviePlayDuration;
@property (strong, nonatomic) UISlider *moviePlaySlider;
@property (nonatomic, assign) NSTimeInterval fadeDelay; //The amount of time that the controls should stay on screen before automatically hiding.
@property (nonatomic, getter = isShowing) BOOL showing; //Are the controls currently showing on screen?
@property (nonatomic) BOOL videoIsEmpty;

@end

@implementation FullScreenMovieViewController

static const NSString *PlayerReadyContext;
static const NSString *PlayerIsPlaying;
static const NSString *PlayerDurationReady;

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoIsEmpty = YES;
    [self loadAssetFromVideo];
    [self setUpVideoPlayView];
    
    self.showing = NO;
    self.fadeDelay = 5.0;
    
    [self setUpBottomBar];
    [self setUpSlider];
    [self setUpPlaybutton];
    [self setUpDurationLabel];
    [self prefersStatusBarHidden];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self addNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (!self.videoIsEmpty) {
        [self.moviePlayerController unregisterNotification];
        [self.moviePlayerController removeObserver:self forKeyPath:@"playerIsReady" context:&PlayerReadyContext];
        [self.moviePlayerController removeObserver:self forKeyPath:@"isPlaying" context:&PlayerIsPlaying];
        [self.moviePlayerController removeObserver:self forKeyPath:@"duration" context:&PlayerDurationReady];
    }
    self.moviePlayerController.isCancelled = YES;
    [self removeNotifications];
    [self stopDurationTimer];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setUpVideoPlayView
{
    self.videoPlayView = [[VideoPlayView alloc] initWithFrame:self.view.bounds];
    [self.videoPlayView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:self.videoPlayView];
    [self.view insertSubview:self.videoPlayView belowSubview:self.customControlsView];
}

- (void)setPlayerInLayer:(AVPlayer *)player
{
    if ((self.moviePlayerController.playerIsReady) &&
        ([self.moviePlayerController.playerItem status] == AVPlayerItemStatusReadyToPlay)) {
        NSLog(@"Setting the video layer\n");
        [self.videoPlayView connectPlayer:player];
        [self.moviePlayerController playVideo];
    } else {
        NSLog(@"Video not ready to play\n");
    }
}

- (void)setUpBottomBar
{
    CGFloat height = CGRectGetHeight(self.view.frame);
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat barHeight = 50.f;
    CGRect rect = CGRectMake(0, height - barHeight, width, barHeight);
    UIView *bottomBar = [[UIView alloc] initWithFrame:rect];
    [bottomBar setBackgroundColor:[UIColor clearColor]];
    [self.customControlsView addSubview:bottomBar];
    [self.customControlsView bringSubviewToFront:bottomBar];
    self.bottomBar = bottomBar;
}

- (void)setUpSlider
{
    CGFloat sliderHeight = 20.f;
    CGFloat sliderWidth = 200.f;
    CGFloat bottomBarHeight = CGRectGetHeight(self.bottomBar.frame);
    CGFloat bottomBarWidth = CGRectGetWidth(self.bottomBar.frame);
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, sliderWidth, sliderHeight)];
    [slider setCenter:CGPointMake(bottomBarWidth / 2, bottomBarHeight / 2)];
    
    UIImage *minTrack = [[UIImage imageNamed:@"SliderFill"] stretchableImageWithLeftCapWidth:14.0 topCapHeight:0.0];
    UIImage *maxTrack = [[UIImage imageNamed:@"SliderBackground"] stretchableImageWithLeftCapWidth:14.0 topCapHeight:0.0];
    UIImage *thumbImage = [UIImage imageNamed:@"ThumbPin"];
    [slider setMinimumTrackImage:minTrack forState:UIControlStateNormal];
    [slider setMaximumTrackImage:maxTrack forState:UIControlStateNormal];
    [slider setThumbImage:thumbImage forState:UIControlStateNormal];
    slider.continuous = YES;
    [self.bottomBar addSubview:slider];
    [self.bottomBar bringSubviewToFront:slider];
    self.moviePlaySlider = slider;
    
    [self.moviePlaySlider addTarget:self action:@selector(durationSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.moviePlaySlider addTarget:self action:@selector(durationSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.moviePlaySlider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpPlaybutton
{
    CGFloat playButtonSize = 50.f;
    UIImage *playButton = [UIImage imageNamed:@"MoviePlayButton"];
    UIImage *stopButton = [UIImage imageNamed:@"MovieStopButton"];
    UIButton *moviePlayButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, playButtonSize, playButtonSize)];
    [moviePlayButton setBackgroundImage:playButton forState:UIControlStateNormal];
    [moviePlayButton setBackgroundImage:stopButton forState:UIControlStateSelected];
    [self.bottomBar addSubview:moviePlayButton];
    self.moviePlayButton = moviePlayButton;
    [self.moviePlayButton addTarget:self action:@selector(stopOrPlay:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)stopOrPlay:(UIButton *)sender
{
    if (!sender.selected) {
        [self playMovie];
    } else {
        [self pauseMovie];
    }
}

- (void)setUpDurationLabel
{
    CGFloat labelSize = 50.f;
    CGFloat origin_x = self.bottomBar.frame.size.width - labelSize;
    CGFloat origin_y = self.bottomBar.frame.size.height - labelSize;
    self.moviePlayDuration = [[UILabel alloc] initWithFrame:CGRectMake(origin_x, origin_y, labelSize, labelSize)];
    [self.bottomBar addSubview:self.moviePlayDuration];
}

- (void)setDurationSliderMaxMinValues
{
    NSInteger maxStepValue = ceilf(CMTimeGetSeconds(self.moviePlayerController.playerItem.duration) * [self.framesPerSecond floatValue]);
    [self.moviePlaySlider setMinimumValue:0];
    [self.moviePlaySlider setMaximumValue:maxStepValue];
    self.moviePlaySlider.value = self.moviePlaySlider.minimumValue;
}

- (void)playMovie
{
//    self.moviePlayButton.selected = YES;
    [self.moviePlayerController playVideo];
}

- (void)pauseMovie
{
//    self.moviePlayButton.selected = NO;
    [self.moviePlayerController pauseVideo];
}

# pragma mark - UIControl/Touch Events

- (void)durationSliderTouchBegan:(UISlider *)slider {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
    [self pauseMovie];
}

- (void)durationSliderTouchEnded:(UISlider *)slider {
    [self.moviePlayerController.player seekToTime:CMTimeMake(ceil(slider.value), [self.framesPerSecond intValue]) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"I want current player time to be  %f", CMTimeGetSeconds(CMTimeMake(ceil(slider.value), [self.framesPerSecond intValue])));
            NSLog(@"Current player time is %f", CMTimeGetSeconds(self.moviePlayerController.player.currentTime));
            [self monitorMoviePlayback:nil];
        }
    }];
    NSLog(@"Slider value is %f", floor(slider.value));
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)durationSliderValueChanged:(UISlider *)slider
{
    NSLog(@"Duration slider value changed");
}

- (void)showControls:(void(^)(void))completion
{
    if (!self.isShowing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
        [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
            self.customControlsView.alpha = 1.f;
        } completion:^(BOOL finished) {
            _showing = YES;
            if (completion)
                completion();
            [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
        }];
    } else {
        if (completion)
            completion();
    }
}

- (void)hideControls:(void(^)(void))completion
{
    if (self.isShowing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
        [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
            self.customControlsView.alpha = 0.f;
        } completion:^(BOOL finished) {
            _showing = NO;
            if (completion)
                completion();
        }];
    } else {
        if (completion)
            completion();
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isShowing ? [self hideControls:nil] : [self showControls:nil];
}

#pragma mark - Notifications
- (void)loadAssetFromVideo
{
    self.moviePlayerController = [[MotionVideoPlayer alloc] init];
    NSURL *videoURL = [NSURL fileURLWithPath:self.videoPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.videoPath]) {
        self.videoIsEmpty = NO;
        [self.moviePlayerController loadAssetFromVideo:videoURL];
        [self.moviePlayerController addObserver:self forKeyPath:@"playerIsReady" options:0 context:&PlayerReadyContext];
        [self.moviePlayerController addObserver:self forKeyPath:@"isPlaying" options:0 context:&PlayerIsPlaying];
        [self.moviePlayerController addObserver:self forKeyPath:@"duration" options:0 context:&PlayerDurationReady];
    } else {
        // Video data object exists but no video saved yet
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == &PlayerReadyContext) {
        if (self.moviePlayerController.playerIsReady) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setPlayerInLayer:self.moviePlayerController.player];
            });
        }
        return;
    } else if (context == &PlayerIsPlaying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self moviePlaybackStateDidChange:self.moviePlayerController.isPlaying];
        });
    } else if (context == &PlayerDurationReady) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self movieDurationAvailable:self.moviePlayerController.duration];
        });
    }
}

- (void)moviePlaybackStateDidChange:(BOOL)isPlaying
{
    if (isPlaying) {
        self.moviePlayButton.selected = YES;
        [self startDurationTimer];
    } else {
        self.moviePlayButton.selected = NO;
        [self stopDurationTimer];
    }
}

- (void)movieDurationAvailable:(float)duration
{
    if (duration) {
        [self setDurationSliderMaxMinValues];
        [self setTimeLabelValues:duration];
    }
}

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)movieFinished:(NSNotification *)note
{
    [self stopDurationTimer];
    [self.moviePlayerController rewindVideo];
    self.moviePlaySlider.value = 0.f;
    [self showControls:nil];
}

- (void)monitorMoviePlayback:(NSTimer *)timer
{
    NSLog(@"Current movie time is %f", CMTimeGetSeconds(self.moviePlayerController.player.currentTime));
    float currentTime = CMTimeGetSeconds(self.moviePlayerController.player.currentTime);
    self.moviePlaySlider.value = ceilf(currentTime * [self.framesPerSecond floatValue]);
}

- (void)setTimeLabelValues:(double)totalTime
{
    double totalMinutes = floor(totalTime / 60.0);
    double totalSeconds = fmod(totalTime, 60.0);
    self.moviePlayDuration.textColor = [UIColor whiteColor];
    self.moviePlayDuration.text = [NSString stringWithFormat:@"%.0f:%02.0f", totalMinutes, totalSeconds];
}

- (void)startDurationTimer
{
    if (self.durationTimer) [self stopDurationTimer];
    
    if ([NSThread isMainThread]) {
        [self selectorToRunInMainThread];
    } else {
        [self performSelectorOnMainThread:@selector(selectorToRunInMainThread) withObject:nil waitUntilDone:NO];
    }
}

- (void)stopDurationTimer
{
    if (self.durationTimer) {
        [self.durationTimer invalidate];
        self.durationTimer = nil;
    }
}

-(void)selectorToRunInMainThread {
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/[self.framesPerSecond floatValue]) target:self selector:@selector(monitorMoviePlayback:) userInfo:nil repeats:YES];
}

@end
