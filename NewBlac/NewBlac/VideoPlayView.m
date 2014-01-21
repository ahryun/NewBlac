//
//  VideoPlayView.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/20/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideoPlayView.h"

@implementation VideoPlayView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
