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
@property (nonatomic) float imageWidth;
@property (nonatomic) float imageHeight;
@property (nonatomic) float focalLength;
@property (strong, nonatomic) NSString *deviceModel;

- (void)straightenCanvas;

@end
