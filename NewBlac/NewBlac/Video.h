//
//  Video.h
//  NewBlac
//
//  Created by Ahryun Moon on 3/18/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * compFilePath;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSNumber * framesPerSecond;
@property (nonatomic, retain) NSNumber * screenRatio;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * facebookVideoID;
@property (nonatomic, retain) NSOrderedSet *photos;
@end

@interface Video (CoreDataGeneratedAccessors)

- (void)insertObject:(Photo *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(Photo *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
@end
