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
        [self setBackgroundColor:[UIColor greenColor]];
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
        
//        [self addDeleteView];
    }
}

//- (void)addDeleteView
//{
//    UIView *deleteView = [[UIView alloc] initWithFrame:self.bounds];
//    // prob. should add an image with a big X on it
//    [deleteView setBackgroundColor:[UIColor redColor]];
//    deleteView.hidden = YES;
//    [self addSubview:deleteView];
//    self.deleteView = deleteView;
//}

@end
