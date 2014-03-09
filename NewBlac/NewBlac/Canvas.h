//
//  Canvas.h
//  NewBlac
//
//  Created by Ahryun Moon on 12/10/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus

#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/ios.h>

#endif

@interface Canvas : NSObject

@property (strong, nonatomic) UIImage *photo;
@property (strong, nonatomic) UIImage *originalImage;
@property (strong, nonatomic) NSArray *coordinates; // In percentage
@property (nonatomic) BOOL orientationChanged;
@property (nonatomic) BOOL cornersDetected;
@property (nonatomic) float imageWidth;
@property (nonatomic) float imageHeight;
@property (nonatomic) float focalLength;
@property (nonatomic) float apertureSize;
@property (nonatomic) float screenAspect;

- (id)initWithPhoto:(UIImage *)photo withFocalLength:(float)focalLength withApertureSize:(float)apertureSize withAspectRatio:(float)aspectRatio;
- (void)unskewWithCoordinates:(NSArray *)coordinates withOriginalImage:(UIImage *)originalImage ifFirstImage:(BOOL)ifFirstImage;

@end
