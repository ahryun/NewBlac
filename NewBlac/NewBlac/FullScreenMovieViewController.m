//
//  FullScreenMovieViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/1/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "FullScreenMovieViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface FullScreenMovieViewController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (weak, nonatomic) IBOutlet UIView *customControlsView;
@property (weak, nonatomic) IBOutlet UINavigationBar *topBar;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (strong, nonatomic) UIView *bottomBar;
@property (strong, nonatomic) UIButton *moviePlayButton;
@property (strong, nonatomic) UILabel *moviePlayDuration;
@property (strong, nonatomic) UISlider *moviePlaySlider;
@property (nonatomic, assign) NSTimeInterval fadeDelay; //The amount of time that the controls should stay on screen before automatically hiding.
@property (nonatomic, getter = isShowing) BOOL showing; //Are the controls currently showing on screen?

@end

@implementation FullScreenMovieViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:self.videoPath]];
    [player prepareToPlay];
    [player.view setFrame: self.view.bounds];  // player's frame must match parent's
    player.controlStyle  = MPMovieControlStyleNone;
    [self.view addSubview:player.view];
    [self.view insertSubview:player.view belowSubview:self.customControlsView];
    self.moviePlayer = player;
    [self addNotifications];
    
    self.showing = NO;
    self.fadeDelay = 5.0;
    
    [self setUpBottomBar];
    [self setUpSlider];
    [self setUpPlaybutton];
    [self setUpDurationLabel];
    [self prefersStatusBarHidden];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setUpBottomBar
{
    float height = CGRectGetHeight(self.view.frame);
    float width = CGRectGetWidth(self.view.frame);
    float barHeight = 50.f;
    CGRect rect = CGRectMake(0, height - barHeight, width, barHeight);
    UIView *bottomBar = [[UIView alloc] initWithFrame:rect];
    [bottomBar setBackgroundColor:[UIColor clearColor]];
    [self.customControlsView addSubview:bottomBar];
    [self.customControlsView bringSubviewToFront:bottomBar];
    self.bottomBar = bottomBar;
}

- (void)setUpSlider
{
    float sliderHeight = 20.f;
    float sliderWidth = 200.f;
    float bottomBarHeight = CGRectGetHeight(self.bottomBar.frame);
    float bottomBarWidth = CGRectGetWidth(self.bottomBar.frame);
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
    float playButtonSize = 50.f;
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
    float labelSize = 50.f;
    float origin_x = self.bottomBar.frame.size.width - labelSize;
    float origin_y = self.bottomBar.frame.size.height - labelSize;
    self.moviePlayDuration = [[UILabel alloc] initWithFrame:CGRectMake(origin_x, origin_y, labelSize, labelSize)];
    [self.bottomBar addSubview:self.moviePlayDuration];
}

- (void)setDurationSliderMaxMinValues
{
    NSInteger maxStepValue = ceilf(self.moviePlayer.duration * [self.framesPerSecond floatValue]);
    [self.moviePlaySlider setMinimumValue:0];
    [self.moviePlaySlider setMaximumValue:maxStepValue];
    self.moviePlaySlider.value = self.moviePlaySlider.minimumValue;
}

- (void)playMovie
{
    self.moviePlayButton.selected = YES;
    [self.moviePlayer play];
}

- (void)pauseMovie
{
    self.moviePlayButton.selected = NO;
    [self.moviePlayer pause];
}

# pragma mark - UIControl/Touch Events

- (void)durationSliderTouchBegan:(UISlider *)slider {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
    [self.moviePlayer pause];
}

- (void)durationSliderTouchEnded:(UISlider *)slider {
    NSTimeInterval playBackTime = floor(slider.value) / self.moviePlayer.duration;
    [self.moviePlayer setCurrentPlaybackTime:playBackTime];
    [self monitorMoviePlayback:nil];
    NSLog(@"Slider value is %f", floor(slider.value));
    NSLog(@"Playback value is %f", self.moviePlayer.currentPlaybackTime);
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)durationSliderValueChanged:(UISlider *)slider {
    NSLog(@"Duration slider value changed");
}

- (void)showControls:(void(^)(void))completion {
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

- (void)hideControls:(void(^)(void))completion {
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.isShowing ? [self hideControls:nil] : [self showControls:nil];
}

#pragma mark - Notifications
- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDurationAvailable:) name:MPMovieDurationAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
}

- (void)movieFinished:(NSNotification *)note
{
    [self stopDurationTimer];
    [self showControls:nil];
}

- (void)monitorMoviePlayback:(NSTimer *)timer
{
    NSLog(@"Current movie time is %f", self.moviePlayer.currentPlaybackTime);
    float currentTime = self.moviePlayer.currentPlaybackTime;
    self.moviePlaySlider.value = ceilf(currentTime * [self.framesPerSecond floatValue]);
}

- (void)setTimeLabelValues:(double)totalTime
{
    double totalMinutes = floor(totalTime / 60.0);
    double totalSeconds = fmod(totalTime, 60.0);
    self.moviePlayDuration.textColor = [UIColor whiteColor];
    self.moviePlayDuration.text = [NSString stringWithFormat:@"%.0f:%02.0f", totalMinutes, totalSeconds];
}

- (void)movieLoadStateDidChange:(NSNotification *)note
{
    switch (self.moviePlayer.loadState) {
        case MPMovieLoadStatePlayable:
        case MPMovieLoadStatePlaythroughOK:
            [self showControls:nil];
            break;
        case MPMovieLoadStateStalled:
        case MPMovieLoadStateUnknown:
            break;
        default:
            break;
    }
}

- (void)moviePlaybackStateDidChange:(NSNotification *)note
{
    NSLog(@"Movie player state is %li", (long)self.moviePlayer.playbackState);
    switch (self.moviePlayer.playbackState) {
        case MPMoviePlaybackStatePlaying:
            self.moviePlayButton.selected = YES;
            [self startDurationTimer];
            //local file
            if ([self.moviePlayer.contentURL.scheme isEqualToString:@"file"]) {
                [self showControls:nil];
            }
            break;
        case MPMoviePlaybackStatePaused:
        case MPMoviePlaybackStateStopped:
            self.moviePlayButton.selected = NO;
            [self stopDurationTimer];
            break;
        default:
            break;
    }
}

- (void)movieDurationAvailable:(NSNotification *)note
{
    NSLog(@"Duration of video is %f", self.moviePlayer.duration);
    [self setDurationSliderMaxMinValues];
    [self setTimeLabelValues:self.moviePlayer.duration];
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

-(void)selectorToRunInMainThread {
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/[self.framesPerSecond floatValue]) target:self selector:@selector(monitorMoviePlayback:) userInfo:nil repeats:YES];
}

- (void)stopDurationTimer
{
    [self.durationTimer invalidate];
    self.durationTimer = nil;
}

@end
