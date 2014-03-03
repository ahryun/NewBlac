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

- (void)viewDidAppear:(BOOL)animated
{
    [self.moviePlayer play];
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
    [self.moviePlayButton addTarget:self action:@selector(stopOrPlay) forControlEvents:UIControlEventTouchUpInside];
}

- (void)stopOrPlay
{
    switch (self.moviePlayer.playbackState) {
        case MPMoviePlaybackStatePlaying:
            [self.moviePlayer pause];
        case MPMoviePlaybackStatePaused:
        case MPMoviePlaybackStateStopped:
            if (self.moviePlayer.currentPlaybackTime >= self.moviePlayer.endPlaybackTime) {
                [self.moviePlayer setCurrentPlaybackTime:0.0];
            }
            [self.moviePlayer play];
            break;
        default:
            break;
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
    [self.moviePlaySlider setMinimumValue:0.f];
    [self.moviePlaySlider setMaximumValue:self.moviePlayer.duration];
    self.moviePlaySlider.value = 0.f;
}

# pragma mark - UIControl/Touch Events

- (void)durationSliderTouchBegan:(UISlider *)slider {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
    [self.moviePlayer pause];
}

- (void)durationSliderTouchEnded:(UISlider *)slider {
    float overflow = fmodf(slider.value, 1/[self.framesPerSecond floatValue]);
    [self.moviePlayer setCurrentPlaybackTime:slider.value - overflow];
    [self monitorMoviePlayback];
    NSLog(@"Duration slider touch ended");
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

//- (void)buttonTouchedDown:(UIButton *)button {
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
//}
//
//- (void)buttonTouchedUpOutside:(UIButton *)button {
//    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
//}
//
//- (void)buttonTouchCancelled:(UIButton *)button {
//    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
//}

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
    self.moviePlayButton.selected = NO;
    [self.durationTimer invalidate];
//    [self.moviePlayer setCurrentPlaybackTime:0.0];
    [self monitorMoviePlayback]; //reset values
    [self showControls:nil];
}

- (void)monitorMoviePlayback
{
    NSLog(@"Current movie time is %f", self.moviePlayer.currentPlaybackTime);
    double currentTime = floor(self.moviePlayer.currentPlaybackTime);
    self.moviePlaySlider.value = ceil(currentTime);
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
    NSLog(@"Movie player state is %i", self.moviePlayer.playbackState);
    switch (self.moviePlayer.playbackState) {
        case MPMoviePlaybackStatePlaying:
            self.moviePlayButton.selected = NO;
            [self startDurationTimer];
            //local file
            if ([self.moviePlayer.contentURL.scheme isEqualToString:@"file"]) {
                [self setDurationSliderMaxMinValues];
                [self showControls:nil];
            }
        case MPMoviePlaybackStatePaused:
        case MPMoviePlaybackStateStopped:
            self.moviePlayButton.selected = YES;
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
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(monitorMoviePlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopDurationTimer
{
    [self.durationTimer invalidate];
}

@end
