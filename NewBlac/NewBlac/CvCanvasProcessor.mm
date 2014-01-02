//
//  CvCanvasProcessor.m
//  NewBlac
//
//  Created by Ahryun Moon on 12/10/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "CvCanvasProcessor.h"

@implementation CvCanvasProcessor

+ (cv::Mat)convertToMat:(UIImage *)uiImage
{
    cv::Mat dst;
    UIImageToMat(uiImage, dst);
    return dst;
}

+ (UIImage *)convertToUIImage:(cv::Mat)destinationImage
{
    UIImage *image = [[UIImage alloc] init];
    image = MatToUIImage(destinationImage);
    return image;
}

+ (void)applyGrayscale:(cv::Mat)destinationImage withKernelSize:(int)kernelSize
{
    cv::Mat dst = destinationImage;
	GaussianBlur( destinationImage, dst, cv::Size( kernelSize, kernelSize ), 0, 0 );
}

@end
