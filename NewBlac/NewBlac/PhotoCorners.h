//
//  PhotoCorners.h
//  NewBlac
//
//  Created by Ahryun Moon on 2/23/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface PhotoCorners : NSManagedObject

@property (nonatomic, retain) NSNumber * bottomLeftxPercent;
@property (nonatomic, retain) NSNumber * bottomLeftyPercent;
@property (nonatomic, retain) NSNumber * bottomRightxPercent;
@property (nonatomic, retain) NSNumber * bottomRightyPercent;
@property (nonatomic, retain) NSNumber * topLeftxPercent;
@property (nonatomic, retain) NSNumber * topLeftyPercent;
@property (nonatomic, retain) NSNumber * topRightxPercent;
@property (nonatomic, retain) NSNumber * topRightyPercent;
@property (nonatomic, retain) Photo *originalPhoto;

@end
