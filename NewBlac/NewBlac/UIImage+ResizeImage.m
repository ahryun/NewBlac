//
//  UIImage+ResizeImage.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/9/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "UIImage+ResizeImage.h"

@implementation UIImage (ResizeImage)

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToMultiplier:(float)multiplier
{
    float imageWidth = image.size.width;
    float imageHeight = image.size.height;
    UIGraphicsBeginImageContext(CGSizeMake(imageWidth * multiplier, imageHeight * multiplier));
    [image drawInRect:CGRectMake(0,0,imageWidth * multiplier,imageHeight * multiplier)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
