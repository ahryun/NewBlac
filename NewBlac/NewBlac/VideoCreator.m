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

@property (nonatomic) dispatch_queue_t queue;

@end

@implementation VideoCreator

- (id)initWithVideo:(Video *)video
{
    self = [super init];
    self.video = video;
    self.queue = dispatch_queue_create("Queue Up Images For Video", NULL);
    
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
    // Remove an existing video file if it exists
    NSError *removeError = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:&removeError];
    } else {
        NSLog(@"Error occured while removing an existing file - %@", [removeError localizedDescription]);
    }
    
    // Create Asset Writer
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(writer);
    
    // Create Writer Input
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    
    // Add the Writer Input to Asset Writer
    NSParameterAssert([writer canAddInput:writerInput]);
    writerInput.expectsMediaDataInRealTime = YES;
    [writer addInput:writerInput];
    
    // Start a session
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    NSUInteger fps = 30;
    double numberOfSecondsPerFrame = 6;
    double frameDuration = fps * numberOfSecondsPerFrame;
    for(int i = 0; i < [imagesArray count]; i++)
    {
        @autoreleasepool {
            [writerInput requestMediaDataWhenReadyOnQueue:self.queue usingBlock:^{
                while ([writerInput isReadyForMoreMediaData]) {
                    NSLog(@"Processing video frame %d out of %d",i,[imagesArray count]);
                    Photo *photo = imagesArray[i];
                    UIImage *image = [UIImage imageWithContentsOfFile:photo.croppedPhotoFilePath];
                    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage withSize:size];
                    BOOL append_ok = NO;
                    if (buffer) {
                        CMTime frameTime = CMTimeMake(i*frameDuration,(int32_t) fps);
                        append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                        if(!append_ok){
                            NSError *error = writer.error;
                            if(error!=nil) {
                                NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                            }
                        }
                    } else {
                        [writerInput markAsFinished];
                        break;
                    }
                }
            }];
        }
    }
    
    [writerInput markAsFinished];
    [writer endSessionAtSourceTime:CMTimeMake(duration * [imagesArray count], 2)];
    [writer finishWritingWithCompletionHandler:^(){
        // Do something
        NSLog(@"Finished creating a video");
    }];
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)cgImage withSize:(CGSize)size
{
    CVPixelBufferRef pixelBuffer = NULL;
    
    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                           [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                           nil];
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBuffer);
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
