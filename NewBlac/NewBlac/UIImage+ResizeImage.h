//
//  UIImage+ResizeImage.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/9/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ResizeImage)

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToMultiplier:(CGFloat)multiplier;

@end
