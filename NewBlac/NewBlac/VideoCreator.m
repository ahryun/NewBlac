//
//  VideoCreator.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/18/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideoCreator.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>
#import "Photo+LifeCycle.h"

@interface VideoCreator()

@end

@implementation VideoCreator

- (id)initWithVideo:(Video *)video
{
    self = [super init];
    self.video = video;
    
    // convert the photos related to this video object into a video
    ////////////////////// Establish video width and height //////////////////////
    CGSize size = CGSizeMake(300, 400);
    int duration = 1;
    ////////////////////// Establish video width and height //////////////////////
    
    NSArray *imagesArray = [self.video imagesArrayInChronologicalOrder];
    [self writeImages:imagesArray ToVideotoPath:self.video.compFilePath size:size duration:duration];
    
    return self;
}

- (void)writeImages:(NSArray *)imagesArray ToVideotoPath:(NSString*)path size:(CGSize)size duration:(int)duration
{
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(writer);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                           [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
  
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:pixelBufferAttributes];
    NSParameterAssert(writerInput);
    NSParameterAssert([writer canAddInput:writerInput]);
    [writer addInput:writerInput];
    
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    for (int i = 0; i < [imagesArray count]; i++) {
        Photo *photo = imagesArray[i];
        UIImage *image = [UIImage imageWithContentsOfFile:photo.croppedPhotoFilePath];
        CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage withSize:size withBufferOptions:pixelBufferAttributes];
//        [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
        [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(duration * i, 2)];
        CVPixelBufferRelease(buffer);
    }
    
    [writerInput markAsFinished];
    [writer endSessionAtSourceTime:CMTimeMake(duration * [imagesArray count], 2)];
    [writer finishWritingWithCompletionHandler:^(){
        // Do something
    }];
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)cgImage withSize:(CGSize)size withBufferOptions:(NSDictionary *)options
{
    CVPixelBufferRef pixelBuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)(options), &pixelBuffer);
    NSParameterAssert(status == kCVReturnSuccess && pixelBuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pixelBuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8,
                                                 4 * size.width, colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    ///////////////////////// Change the position of image origin ////////////////////////////////
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), cgImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

@end
