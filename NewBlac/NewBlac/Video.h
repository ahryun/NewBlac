//
//  Video.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/17/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * compFilePath;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * screenRatio;
@property (nonatomic, retain) NSSet *photos;
@end

@interface Video (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
