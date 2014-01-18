//
//  VideoCreator.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/18/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideoCreator.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoCreator

- (void)setVideo:(Video *)video
{
    _video = video;
    
    // convert the photos related to this video object into a video
    [self writeImageToVideo];
}

- (void)writeImageToVideo
{
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:self.video.compFilePath];
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(writer);
    
    ////////////////////// Establish video width and height //////////////////////
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
}

@end
