//
//  Photo.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/5/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PhotoCorners, Video;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * originalPhotoFilePath;
@property (nonatomic, retain) NSString * croppedPhotoFilePath;
@property (nonatomic, retain) NSDate * timeTaken;
@property (nonatomic, retain) Video *video;
@property (nonatomic, retain) PhotoCorners *canvasRect;

@end
