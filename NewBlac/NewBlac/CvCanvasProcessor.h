//
//  CvCanvasProcessor.h
//  NewBlac
//
//  Created by Ahryun Moon on 12/10/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//
// OpenCV C++ functions

#import <Foundation/Foundation.h>

#ifdef __cplusplus

#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/ios.h>

#endif

@interface CvCanvasProcessor : NSObject

+ (cv::Mat)convertToMat:(UIImage *)uiImage;
+ (void)applyGrayscale:(cv::Mat)destinationImage  withKernelSize:(int)kernelSize;
+ (UIImage *)convertToUIImage:(cv::Mat)destinationImage;

@end
