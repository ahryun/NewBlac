//
//  VideoCollectionCell.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideoCollectionCell.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoCollectionCell

// Since the cell is registered through Storyboard, I need to use initWithCoder instead of initWithFrame
- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSLog(@"Hey I'm in awakeFromNib\n");
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"delete_image" ofType:@"png"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imagePath]];
        [imageView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]];
        imageView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        [self addSubview:imageView];
        self.imageView = imageView;
        self.imageView.alpha = 0.0;
    }
    return self;
}

- (void)displayVideo
{
    if (self.videoURL) {
        AVURLAsset *video = [[AVURLAsset alloc] initWithURL:self.videoURL options:nil];
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:video];
        imageGenerator.appliesPreferredTrackTransform = YES;
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        NSError *error = NULL;
        CMTime actualTime;
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:video.duration actualTime:&actualTime error:&error];
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        [self addSubview:imageView];
        self.contentMode = UIViewContentModeScaleAspectFit;
        [self bringSubviewToFront:self.imageView];
    }
}

@end
