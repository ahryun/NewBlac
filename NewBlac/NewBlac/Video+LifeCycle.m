//
//  Video+LifeCycle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/16/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Video+LifeCycle.h"
#import "Photo+LifeCycle.h"

@implementation Video (LifeCycle)

+ (Video *)videoWithPath:(NSString *)path inManagedObjectContext:(NSManagedObjectContext *)context
{
    // Find if the video exists
    // If doesn't exist, create one
    
    Video *video = nil;
    
    if (path) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Video"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES]];
        request.predicate = [NSPredicate predicateWithFormat:@"compFilePath = %@", path];
        
        NSError *error = nil;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || [matches count] > 1) {
            // Handle error
        } else if (![matches count]) {
            video = [NSEntityDescription insertNewObjectForEntityForName:@"Video" inManagedObjectContext:context];
            [video setCompFilePath:path];
            [video setDateCreated:[NSDate date]];
        } else {
            video = [matches lastObject];
        }
    } else {
        path = [Video getRandomFilePath];
        video = [NSEntityDescription insertNewObjectForEntityForName:@"Video" inManagedObjectContext:context];
        [video setCompFilePath:path];
        [video setDateCreated:[NSDate date]];
    }
    
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

+ (void)removeVideo:(Video *)video inManagedContext:(NSManagedObjectContext *)context
{
    if (video && context) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        if ([fileManager fileExistsAtPath:video.compFilePath]) {
            BOOL success = [fileManager removeItemAtPath:video.compFilePath error:&error];
            if (!success) NSLog(@"Error happened while trying to remove video in file system: %@\n", error);
        }
        [context deleteObject:video];
        NSLog(@"You went back to gallery without saving the video. It's been deleted\n");
    } else {
        NSLog(@"Something went wrong while deleting the video");
    }
}

+ (void)removeVideosInManagedContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Video"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES]];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    if ([matches count]) {
        for (Video *video in matches) {
            // If no photos, delete the video
            if (![video.photos count]) [Video removeVideo:video inManagedContext:context];
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

// this overwrites the original addPhotosObjectfunction to get around the known bug
- (void)addPhotosObject:(Photo *)photo {
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet addObject:photo];
    self.photos = tempSet;
}

@end
