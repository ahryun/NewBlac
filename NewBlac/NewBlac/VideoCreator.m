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

@property (nonatomic, strong) NSArray *imagesArray;
@property (nonatomic) CGSize screenSize;
@property (nonatomic, strong) AVAssetWriter *writer;

@end

@implementation VideoCreator

- (id)initWithVideo:(Video *)video withScreenSize:(CGSize)size
{
    self = [super init];
    self.video = video;
    self.screenSize = size;
    self.videoDoneCreating = NO;
    self.numberOfFramesInLastCompiledVideo = 0;
    return self;
}

- (NSArray *)imagesArray
{
    if (!_imagesArray) {
        _imagesArray = [self.video imagesArrayInOrder];
    }
    return _imagesArray;
}

- (void)writeImagesToVideo
{
    // Remove an existing video file if it exists
    self.videoDoneCreating = NO;
    NSError *removeError = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.video.compFilePath]) {
        BOOL removalSuccess = [fileManager removeItemAtPath:self.video.compFilePath error:&removeError];
        if (!removalSuccess) NSLog(@"Error occured while removing an existing file - %@", [removeError localizedDescription]);
    }
    
    // Create Asset Writer
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:self.video.compFilePath];
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    self.writer = writer;
    NSParameterAssert(self.writer);
    
    // Create Writer Input
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:self.screenSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:self.screenSize.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                           [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                           nil];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:pixelBufferAttributes];
    NSParameterAssert(writerInput);
    
    // Add the Writer Input to Asset Writer
    NSParameterAssert([self.writer canAddInput:writerInput]);
    writerInput.expectsMediaDataInRealTime = YES;
    [self.writer addInput:writerInput];
    
    // Start a session
    [self.writer startWriting];
    [self.writer startSessionAtSourceTime:kCMTimeZero];
    
    NSUInteger fps = [self.video.framesPerSecond integerValue];
    double frameDuration = 1;
    for(int i = 0; i < [self.imagesArray count]; i++) {
        @autoreleasepool {
            NSLog(@"Processing video frame %d out of %lu",(i + 1),(unsigned long)[self.imagesArray count]);
            Photo *photo = self.imagesArray[i];
            UIImage *image = [UIImage imageWithData:photo.croppedPhoto];
            CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage withSize:self.screenSize];
            BOOL append_ok = NO;
            int nthTry = 0;
            int maximumTries = 30;
            CMTime frameTime = CMTimeMake(frameDuration * i,(int32_t)fps);
            while (!append_ok && nthTry < maximumTries) {
                if (buffer && adaptor.assetWriterInput.readyForMoreMediaData) {
                    append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                    if(!append_ok){
                        NSError *error = writer.error;
                        if(error!=nil) NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                    } else {
                        NSLog(@"Pixel buffer %i was appended to adaptor successfully\n", i + 1);
                    }
                } else {
                    printf("adaptor not ready %d at %d-th try\n", i, nthTry);
                    // There may be a better way
                    [NSThread sleepForTimeInterval:0.1];
                }
                nthTry++;
            }
            CVPixelBufferRelease(buffer);
        }
    }
    
    [writerInput markAsFinished];
    NSLog(@"End session source time is %f", CMTimeGetSeconds(CMTimeMake(frameDuration * [self.imagesArray count], (int32_t)fps)));
    [self.writer endSessionAtSourceTime:CMTimeMake(frameDuration * [self.imagesArray count], (int32_t)fps)];
    __weak VideoCreator *weakSelf = self;
    [self.writer finishWritingWithCompletionHandler:^(){
        // Do something
        NSLog(@"Finished creating a video");
        NSLog(@"No of tracks in this video is %lu", (unsigned long)[[[AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.video.compFilePath]] tracks] count]);
        
        weakSelf.videoDoneCreating = YES;
        
        weakSelf.numberOfFramesInLastCompiledVideo = [self.imagesArray count];
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
    float originalImageRatio = (float)CGImageGetWidth(cgImage) / (float)CGImageGetHeight(cgImage);
    CGSize imageSize = [self getImageSizewithScreenSize:size withImageSize:originalImageRatio];
    // Below added to un-Blur the image
//    CGContextScaleCTM(context, imageSize.width/size.width, imageSize.height/size.height);
    // Above added to un-Blur the image
    CGContextDrawImage(context, CGRectMake((size.width - imageSize.width) / 2, (size.height - imageSize.height) / 2, imageSize.width, imageSize.height), cgImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

- (CGSize)getImageSizewithScreenSize:(CGSize)screenSize withImageSize:(float)originalImageRatio
{
    CGSize imageSize;
    float screenRatio = screenSize.width / screenSize.height;
    float videoRatio = [self.video.screenRatio floatValue];
    // This is so that if the video only contains non corners detected photos, meaning aspect ratio of ZERO, the video still shows the photos in correct dimensions
    if (videoRatio <= 0) videoRatio = originalImageRatio;
    if (videoRatio >= screenRatio) {
        imageSize.width = (int)screenSize.width;
        imageSize.height = (int)(screenSize.width / videoRatio);
    } else {
        imageSize.height = (int)screenSize.height;
        imageSize.width = (int)(screenSize.height * videoRatio);
    }
    
    return imageSize;
}

@end
