//
//  VideoCollectionCell.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideoCollectionCell.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoCollectionCell() <UIScrollViewDelegate>

@property (nonatomic) BOOL pulling;

@end

@implementation VideoCollectionCell

// Since the cell is registered through Storyboard, I need to use initWithCoder instead of initWithFrame
- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSLog(@"Hey I'm in initWithCoder\n");

    self = [super initWithCoder:aDecoder];
    if (self) {
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.clipsToBounds = NO;
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        scrollView.delaysContentTouches = YES;
        scrollView.delegate = self;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectCell)];
        [scrollView addGestureRecognizer:tapGesture];
        
        [self.contentView addSubview:scrollView];
        self.scrollView = scrollView;
        self.pulling = NO;
    }
    return self;
}

#define OFFSET_TOP               (80)
#define PULL_THRESHOLD           (50)
#define CELL_HEIGHT              (330)

- (void)prepareScrollView
{
    NSLog(@"I'm in prepareScrollView\n");
    // Set up scroll view
    [self.scrollView setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self.scrollView setContentSize:CGSizeMake(self.bounds.size.width, self.bounds.size.height + OFFSET_TOP)];
    [self.scrollView setContentOffset:CGPointMake(0, OFFSET_TOP)];
    
    // Set up delete button within scroll view programmatically
    if (!self.deleteButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 25, self.scrollView.frame.size.width, 30);
        [button setTitle:@"DELETE" forState:UIControlStateNormal];
        UIImage *scissorImage = [UIImage imageNamed:@"DeleteIcon"];
        scissorImage = [scissorImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [button setImage:scissorImage forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
        button.alpha = 0;
        [button setTitleColor:[UIColor colorWithRed:(51.0/255) green:(51.0/255) blue:(51.0/255) alpha:1.0f] forState:UIControlStateNormal];
        self.deleteButton = button;
        [self.scrollView addSubview:button];
        [self.deleteButton addTarget:self action:@selector(sendDeleteMessage) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)sendDeleteMessage
{
    // Tell delegate to delet this video
    [self.delegate deleteButtonPressed:self];
}

- (void)selectCell
{
    [self.delegate selectItemAtIndexPath:self];
}

- (void)displayVideo
{
    if (!self.imageView) {
        UIImageView *imageView = [[UIImageView alloc] init];
        [imageView setFrame:CGRectMake(0, OFFSET_TOP, self.bounds.size.width, CELL_HEIGHT)];
        [imageView.layer setCornerRadius:15.0f];
        imageView.clipsToBounds = YES;
        
        // This makes the video darkened until it's in the middle and playing
        if (!self.maskView) {
            self.maskView = [[UIView alloc] initWithFrame:imageView.bounds];
            self.maskView.backgroundColor = [UIColor blackColor];
            self.maskView.alpha = 0.3;
            [imageView addSubview:self.maskView];
        }
        
        [self.scrollView addSubview:imageView];
        self.imageView = imageView;
    }
}

- (void)prepareVideoLayer:(AVPlayer *)videoPlayer
{
    if (!self.playerLayer) {
        VideoPlayView *playerLayer = [[VideoPlayView alloc] initWithFrame:self.imageView.bounds];
        [playerLayer setPlayer:videoPlayer];
        [self.imageView addSubview:playerLayer];
        self.playerLayer = playerLayer;
    }
}

- (void)removeVideoLayer
{
    if (self.playerLayer) [self.playerLayer removeFromSuperview];
    self.playerLayer = nil;
}


#pragma mark - ScrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = OFFSET_TOP - self.scrollView.contentOffset.y; // 0 - 80
    if (offset > PULL_THRESHOLD && !self.pulling) {
        self.deleteButton.alpha = offset / OFFSET_TOP;
        [self.delegate scrollingCellDidBeginPulling:self];
        self.pulling = YES;
    }
    if (self.pulling) self.deleteButton.alpha = offset / OFFSET_TOP;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (targetContentOffset->y < (OFFSET_TOP / 2)) {
        *targetContentOffset = CGPointMake(self.scrollView.contentOffset.x, 0);
        self.deleteButton.alpha = 1;
    } else {
        *targetContentOffset = CGPointMake(self.scrollView.contentOffset.x, OFFSET_TOP);
        self.deleteButton.alpha = 0;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        self.pulling = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pulling = NO;
}

#pragma mark - Convenience Functions

- (void)reset
{
    self.pulling = NO;
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, OFFSET_TOP)];
}

@end
