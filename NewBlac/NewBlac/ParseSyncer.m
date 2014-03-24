//
//  ParseSyncer.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/19/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "ParseSyncer.h"
#import <Parse/Parse.h>

@implementation ParseSyncer

// Designated initializer
+ (void)addVideo:(Video *)video inContext:(NSManagedObjectContext *)context
{
    // Make sure the user is saved on Parse. If the user has not been saved on Parse, trying to get ACL from the user will crash the app.
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" equalTo:[PFUser currentUser].objectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        PFUser *user = [objects lastObject];
        if (video.compFilePath && user) {
            NSData *videoData;
            
            // If there is no file at the path, pass nil as the video is created.
            if ([[NSFileManager defaultManager] fileExistsAtPath:video.compFilePath]) {
                videoData = [NSData dataWithContentsOfFile:video.compFilePath];
            } else {
                videoData = nil;
            }
            
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *userCreatedVideo = [PFObject objectWithClassName:@"UserCreatedVideo"];
            NSString *videoFileName = [[video.compFilePath componentsSeparatedByString:@"/"] lastObject];
            
            userCreatedVideo.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [userCreatedVideo setObject:[PFFile fileWithName:videoFileName data:videoData] forKey:@"videoFile"];
            [userCreatedVideo setObject:[PFUser currentUser] forKey:@"user"];
            
            NSError *addError;
            [userCreatedVideo save:&addError];
            if (addError) {
                NSLog(@"Video %@ got added\n", video.parseID);
                [context performBlock:^{
                    video.parseID = userCreatedVideo.objectId;
                }];
            } else {
                NSLog(@"Video failed to be added %@, %@", addError, [addError userInfo]);
            }
        }
    }];
}

+ (void)updateVideosInContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Video" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSError *fetchError;
    NSArray *matches = [context executeFetchRequest:request error:&fetchError];
    
    // Retrieve the object by id
    for (Video *video in matches) {
        if (video.parseID) {
            PFQuery *query = [PFQuery queryWithClassName:@"UserCreatedVideo"];
            [query getObjectInBackgroundWithId:video.parseID block:^(PFObject *userCreatedVideo, NSError *error) {
                if (!error) {
                    if (video.dateModified) {
                        if ([userCreatedVideo.updatedAt compare:video.dateModified] == NSOrderedAscending) {
                            NSData *videoData = [NSData dataWithContentsOfFile:video.compFilePath];
                            NSString *videoFileName = [[video.compFilePath componentsSeparatedByString:@"/"] lastObject];
                            userCreatedVideo[@"videoFile"] = [PFFile fileWithName:videoFileName data:videoData];;
                            NSError *saveError;
                            [userCreatedVideo save:&saveError];
                            if (saveError) {
                                NSLog(@"Video %@ got updated\n", video.parseID);
                            } else {
                                NSLog(@"Video failed to be updated %@, %@", saveError, [saveError userInfo]);
                            }
                        }
                    } else {
                        NSLog(@"The video has not been compiled\n");
                    }
                } else {
                    NSLog(@"Error occurred while getting video object from Parse in updateVideosInContext: %@\n", error);
                    if (error.code == 101) {
                        // If error code is 101, that means the video on the user's device does not exist on Parse. Add it.
                        NSLog(@"ObjectNotFound #101 error. Trying to add the video object to Parse\n");
                        [ParseSyncer addVideo:video inContext:context];
                    }
                }
            }];
        } else {
            // If the video in Core Data does not exist in Parse, add it.
            [ParseSyncer addVideo:video inContext:context];
            NSLog(@"There was a video that was not on Parse. Adding it\n");
        }
    }
}

+ (void)removeVideo:(Video *)video
{
    // Retrieve the object by id
    if (video.parseID) {
        PFQuery *query = [PFQuery queryWithClassName:@"UserCreatedVideo"];
        [query getObjectInBackgroundWithId:video.parseID block:^(PFObject *userCreatedVideo, NSError *error) {
            if (!error) {
                NSError *deleteError;
                [userCreatedVideo delete:&deleteError];
                if (deleteError) {
                    NSLog(@"Video deleted");
                } else {
                    NSLog(@"Video failed to be deleted %@, %@", deleteError, [deleteError userInfo]);
                }
                
            } else {
                NSLog(@"Error occurred while getting video object from Parse in removeVideo: %@\n", error);
            }
        }];
    }
}

+ (void)removeVideosInContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Video" inManagedObjectContext:context];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"parseID" ascending:YES];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setSortDescriptors:@[sortDescriptor]];
    NSError *fetchError;
    NSArray *matches = [context executeFetchRequest:request error:&fetchError];
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserCreatedVideo"];
    [query orderByAscending:@"objectID"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSMutableArray *mutableMatches = [matches mutableCopy];
        for (PFObject *userCreatedVideo in objects) {
            for (Video *video in mutableMatches) {
                if ([userCreatedVideo.objectId isEqualToString:video.parseID]) {
                    [mutableMatches removeObject:video];
                    break;
                } else {
                    NSError *deleteError;
                    [userCreatedVideo delete:&deleteError];
                    if (deleteError) {
                        NSLog(@"Video deleted");
                    } else {
                        NSLog(@"Video failed to be deleted %@, %@", deleteError, [deleteError userInfo]);
                    }
                }
            }
        }
    }];
    
}

@end
