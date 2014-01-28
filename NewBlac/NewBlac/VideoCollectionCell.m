//
//  VideoCollectionCell.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideoCollectionCell.h"
#import <MediaPlayer/MPMoviePlayerController.h>

@implementation VideoCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:self.videoURL];
        [player prepareToPlay];
        [player.view setFrame: self.bounds];  // player's frame must match parent's
        [self addSubview: player.view];
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

@end
