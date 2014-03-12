//
//  Photo.h
//  NewBlac
//
//  Created by Ahryun Moon on 3/11/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PhotoCorners, Video;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSNumber * apertureSize;
@property (nonatomic, retain) NSData * croppedPhoto;
@property (nonatomic, retain) NSNumber * focalLength;
@property (nonatomic, retain) NSNumber * indexInVideo;
@property (nonatomic, retain) NSData * originalPhoto;
@property (nonatomic, retain) NSDate * timeTaken;
@property (nonatomic, retain) NSNumber * cornersDetected;
@property (nonatomic, retain) PhotoCorners *canvasRect;
@property (nonatomic, retain) Video *video;

@end
