//
//  Photo.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/4/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Video;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * originalPhotoFilePath;
@property (nonatomic, retain) NSString * croppedPhotoFilePath;
@property (nonatomic, retain) NSNumber * orderInVideo;
@property (nonatomic, retain) Video *video;
@property (nonatomic, retain) NSManagedObject *canvasRect;

@end
