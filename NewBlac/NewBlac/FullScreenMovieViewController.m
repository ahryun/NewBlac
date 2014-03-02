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
@property (weak, nonatomic) IBOutlet UIButton *moviePlayButton;
@property (weak, nonatomic) IBOutlet UISlider *moviePlaySlider;
@property (weak, nonatomic) IBOutlet UILabel *moviePlayDuration;
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
    self.showing = NO;
    self.fadeDelay = 5.0;
    
    [self setUpSlider];
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

- (void)setUpSlider
{
    UIImage *minTrack = [UIImage imageNamed:@"SliderFill"];
    UIImage *maxTrack = [UIImage imageNamed:@"SliderBackground"];
    minTrack = [minTrack resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
    [self.moviePlaySlider setMinimumTrackImage:minTrack forState:UIControlStateNormal];
    [self.moviePlaySlider setMaximumTrackImage:maxTrack forState:UIControlStateNormal];
    [self.moviePlaySlider setMinimumValue:0.f];
    [self.moviePlaySlider setMaximumValue:self.moviePlayer.duration];
    self.moviePlaySlider.value = 0.f;
    self.moviePlaySlider.continuous = YES;
    [self.moviePlaySlider addTarget:self action:@selector(durationSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.moviePlaySlider addTarget:self action:@selector(durationSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.moviePlaySlider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.moviePlaySlider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
}

# pragma mark - UIControl/Touch Events

- (void)durationSliderTouchBegan:(UISlider *)slider {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
    [self.moviePlayer pause];
}

- (void)durationSliderTouchEnded:(UISlider *)slider {
    [self.moviePlayer setCurrentPlaybackTime:floor(slider.value)];
    [self.moviePlayer play];
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)durationSliderValueChanged:(UISlider *)slider {
    double currentTime = floor(slider.value);
    self.moviePlaySlider.value = ceil(currentTime);
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


@end
