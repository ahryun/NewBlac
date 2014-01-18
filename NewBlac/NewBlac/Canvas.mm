//
//  Canvas.m
//  NewBlac
//
//  Created by Ahryun Moon on 12/10/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "Canvas.h"
#include "CanvasStraightener.hpp"

@implementation Canvas

@synthesize photo = _photo;
- (UIImage *)photo
{
    if (!_photo) {
        _photo = [[UIImage alloc] init];
    }
    return _photo;
}

- (void)setPhoto:(UIImage *)photo
{
    if (_photo != photo) {
        _photo = [self scaleAndRotateImage:photo ifOriginal:false];
    }
}

@synthesize originalImage = _originalImage;
- (UIImage *)originalImage
{
    if (!_originalImage) {
        _originalImage = [[UIImage alloc] init];
    }
    return _originalImage;
}

- (void)setOriginalImage:(UIImage *)originalImage
{
    if (_originalImage != originalImage) {
        if (!self.orientationChanged) {
            _originalImage = [self scaleAndRotateImage:originalImage ifOriginal:true];
            self.orientationChanged = YES;
        } else {
            _originalImage = originalImage;
        }
    }
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (NSArray *)convertToNSArray:(cv::Point2f[])array
{
    NSMutableArray *convertedArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; i++) {
        NSMutableArray *point = [NSMutableArray arrayWithObjects:
                                 [NSNumber numberWithFloat:array[i].x / self.imageWidth],
                                 [NSNumber numberWithFloat:array[i].y / self.imageHeight], nil];
        [convertedArray addObject:point];
    }
    NSLog(@"The converted array is %@", convertedArray);
    
    return convertedArray;
}

- (cv::Point2f *)convertToPointArrayInRealPixel:(NSArray *)coordinates
{
    int count = [coordinates count];
    cv::Point2f *convertedArray = new cv::Point2f[count];
    for (int i = 0; i < count; i++) {
        convertedArray[i] = cv::Point2f([[coordinates objectAtIndex:i][0] floatValue] * self.imageWidth,
                                        [[coordinates objectAtIndex:i][1] floatValue] * self.imageHeight);
//        NSLog(@"The point array is %f and %f", convertedArray[i].x, convertedArray[i].y);
    }
    
    return convertedArray;
}

// Designated init for Canvas object
- (id)initWithPhoto:(UIImage *)photo withFocalLength:(float)focalLength withApertureSize:(float)apertureSize withAspectRatio:(float)aspectRatio;
{
    self = [super init];
    
    [self setPhoto: photo];
    [self setOriginalImage: photo];
    [self setImageWidth:photo.size.width];
    [self setImageHeight:photo.size.height];
    [self setFocalLength:focalLength];
    [self setApertureSize:apertureSize];
    if (aspectRatio) [self setScreenAspect:aspectRatio];
    
    [self straightenCanvas];
    
    return self;
}

- (void)straightenCanvas
{
    NSLog(@"Photo dimensions are %f by %f", self.imageWidth, self.imageHeight);
    
    CanvasStraightener::Images images;
    images.photoCopy = [self cvMatFromUIImage:self.originalImage];
    self.originalImage = nil;
    images.canvas = [self cvMatFromUIImage:self.photo];
    images.imageWidth = self.imageWidth;
    images.imageHeight = self.imageHeight;
    images.focalLength = self.focalLength;
    images.sensorWidth = self.apertureSize <= 2.30 ? 4.8: 4.54;
    images.initialStraighteningDone = false;
    images.screenAspectRatio = self.screenAspect ? 0 : self.screenAspect;
    
    CanvasStraightener canvasStraightener(images);
    self.originalImage = [self UIImageFromCVMat:canvasStraightener.images_.photoCopy];
    self.coordinates = [self convertToNSArray:canvasStraightener.images_.inputQuad];
    if (!self.screenAspect) self.screenAspect = canvasStraightener.images_.screenAspectRatio;
}

- (void)unskewWithCoordinates:(NSArray *)coordinates withOriginalImage:(UIImage *)originalImage ifFirstImage:(BOOL)ifFirstImage;
{
    CanvasStraightener::Images images;
    images.photoCopy = [self cvMatFromUIImage:originalImage];
    images.canvas = [self cvMatFromUIImage:self.photo];
    images.imageWidth = self.imageWidth;
    images.imageHeight = self.imageHeight;
    images.focalLength = self.focalLength;
    images.sensorWidth = self.apertureSize <= 2.30 ? 4.8: 4.54;
    images.initialStraighteningDone = true;
    // Screen aspect ratio needs to be recalculated so I pass zero into CanvasStraightener to force it to recalculate the aspect
    images.screenAspectRatio = ifFirstImage ? 0 : self.screenAspect;
    
    // Fill out the input quads of vertices in real pixel
    // Meaning the floating points are not in percentage form
    cv::Point2f *floatArray = [self convertToPointArrayInRealPixel:coordinates];
    for (int i = 0; i < [coordinates count]; i++) {
        images.inputQuad[i] = floatArray[i];
        NSLog(@"Converted array is %f, %f\n", floatArray[i].x, floatArray[i].y);
    }
    
    CanvasStraightener canvasStraightener(images);
    self.originalImage = [self UIImageFromCVMat:canvasStraightener.images_.photoCopy];
    self.coordinates = coordinates;
    // Saves the new value for screen aspect ratio
    self.screenAspect = canvasStraightener.images_.screenAspectRatio;
}

// Images captured by iPhone camera are rotated 90 degree automatically
// This function corrects the orientation
- (UIImage *)scaleAndRotateImage:(UIImage *)image ifOriginal:(BOOL)iforiginal
{
    int kMaxResolution = 480;
    
    CGImageRef imgRef = image.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (!iforiginal) {
        if (width > kMaxResolution || height > kMaxResolution) {
            CGFloat ratio = width/height;
            if (ratio > 1) {
                bounds.size.width = kMaxResolution;
                bounds.size.height = bounds.size.width / ratio;
            }
            else {
                bounds.size.height = kMaxResolution;
                bounds.size.width = bounds.size.height * ratio;
            }
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 1.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}


@end
