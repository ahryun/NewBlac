//
//  PhotoCorners.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/4/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface PhotoCorners : NSManagedObject

@property (nonatomic, retain) NSNumber * bottomLeftx;
@property (nonatomic, retain) NSNumber * bottomLefty;
@property (nonatomic, retain) NSNumber * bottomRightx;
@property (nonatomic, retain) NSNumber * topRighty;
@property (nonatomic, retain) NSNumber * topRightx;
@property (nonatomic, retain) NSNumber * topLefty;
@property (nonatomic, retain) NSNumber * topLeftx;
@property (nonatomic, retain) NSNumber * bottomRighty;
@property (nonatomic, retain) Photo *originalPhoto;

@end
