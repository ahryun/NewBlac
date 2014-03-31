//
//  Video+LifeCycle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/16/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Video+LifeCycle.h"
#import "Photo+LifeCycle.h"
#import "ParseSyncer.h"

@implementation Video (LifeCycle)

+ (Video *)videoWithPath:(NSString *)path
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    Video *video;
    if (path) {
        video = [Video MR_findFirstByAttribute:@"compFilePath" withValue:path inContext:context];
        
        if (!video) {
            video = [Video MR_createInContext:context];
            video.compFilePath = path;
            video.dateCreated = [NSDate date];
        }
    } else {
        path = [Video getRandomFilePath];
        video = [Video MR_createInContext:context];
        [video setCompFilePath:path];
        [video setDateCreated:[NSDate date]];
    }
    
    // Add this video to Parse
    [ParseSyncer addVideo:video];
    
    [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"An error occurred while trying to save context %@", error);
    }];
    
    return video;
}

+ (NSString *)getRandomFilePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath =[documentPaths objectAtIndex:0];
    NSString *originalVideoDir = [documentPath stringByAppendingPathComponent:@"Videos"];
    [fileManager createDirectoryAtPath:originalVideoDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *videoPath = [originalVideoDir stringByAppendingPathComponent:UUID];
    NSString *videoPathWithFormat = [videoPath stringByAppendingString:@".mov"];
    
    if ([fileManager fileExistsAtPath:videoPathWithFormat]) NSLog(@"File exists. Possibly UUID collision. This should never happen.\n");
    
    return videoPathWithFormat;
}

+ (void)removeVideo:(Video *)video
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];

    if (video && context) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        if ([fileManager fileExistsAtPath:video.compFilePath]) {
            BOOL success = [fileManager removeItemAtPath:video.compFilePath error:&error];
            if (!success) NSLog(@"Error happened while trying to remove video in file system: %@\n", error);
        }
        
        [video MR_deleteInContext:context];
        [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"An error occurred while trying to save context %@", error);
        }];
        
        NSLog(@"You went back to gallery without saving the video. It's been deleted\n");
    } else {
        NSLog(@"Something went wrong while deleting the video");
    }
}

+ (void)removeVideos
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    NSArray *matches = [Video MR_findAllSortedBy:@"dateCreated" ascending:YES inContext:context];
    if ([matches count]) {
        for (Video *video in matches) {
            // If no photos, delete the video
            if (![video.photos count]) {
                [Video removeVideo:video];
                // Remove these videos from Parse as well
                [ParseSyncer removeVideo:video];
            }
        }
    } else {
        // Handle Error
        NSLog(@"No videos\n");
    }
}

- (NSArray *)imagesArrayInOrder
{
    return [self.photos array];
}

// This is to avoid adding more than max number, currently 75 per video, of photos to a single video
- (BOOL)addPhotosObjectWithAuthentification:(Photo *)photo
{
    if ([self.photos count] < MAX_PHOTO_COUNT_PER_VIDEO) {
        [self addPhotosObject:photo];
        return YES;
    } else {
        return NO;
    }
}

// this overwrites the original addPhotosObjectfunction to get around the known bug
- (void)addPhotosObject:(Photo *)photo
{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet addObject:photo];
    self.photos = tempSet;
    [self updateAPhotoIndexInVideo:photo atEnd:YES];
}

- (void)updateAPhotoIndexInVideo:(Photo *)photo atEnd:(BOOL)atEnd
{
    if (atEnd) {
        [photo setIndexInVideo:[NSNumber numberWithInteger:[self.photos count]]];
    } else {
        [photo setIndexInVideo:[NSNumber numberWithInteger:[self.photos indexOfObject:photo]]];
    }
}

- (void)updateAllPhotoIndexInVideo
{
    for (Photo *photo in self.photos) {
        [photo setIndexInVideo:[NSNumber numberWithInteger:[self.photos indexOfObject:photo]]];
    }
}

@end
