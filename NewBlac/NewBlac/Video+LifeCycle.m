//
//  Video+LifeCycle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/16/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Video+LifeCycle.h"

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


@end
