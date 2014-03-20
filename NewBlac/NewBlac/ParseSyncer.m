//
//  ParseSyncer.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/19/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "ParseSyncer.h"
#import <Parse/Parse.h>

@interface ParseSyncer()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation ParseSyncer

// Designated initializer
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    
    _managedObjectContext = context;
    
    return self;
}

- (void)addVideo:(Video *)video
{
    NSData *videoData = [NSData dataWithContentsOfFile:video.compFilePath];
    NSString *videoFileName = [video.compFilePath componentsSeparatedByString:@"Document"][1];
    PFFile *videoFile = [PFFile fileWithName:videoFileName data:videoData];
    
    // Save PFFile
    [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Hide old HUD, show completed HUD (see example for code)
            
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *userCreatedVideo = [PFObject objectWithClassName:@"UserCreatedVideo"];
            [userCreatedVideo setObject:videoFile forKey:@"videoFile"];
            
            // Set the access control list to current user for security purposes
            userCreatedVideo.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            
            PFUser *user = [PFUser currentUser];
            [userCreatedVideo setObject:user forKey:@"user"];
            
            [userCreatedVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self.managedObjectContext performBlock:^{
                        video.parseID = userCreatedVideo.objectId;
                    }];
                } else {
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        }
        else{
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)updateVideo:(Video *)video
{
    PFQuery *query = [PFQuery queryWithClassName:@"UserCreatedVideo"];
    
    // Retrieve the object by id
    [query getObjectInBackgroundWithId:video.parseID block:^(PFObject *userCreatedVideo, NSError *error) {
        // Now let's update it with some new data. In this case, only cheatMode and score
        // will get sent to the cloud. playerName hasn't changed.
        NSData *videoData = [NSData dataWithContentsOfFile:video.compFilePath];
        userCreatedVideo[@"videoFile"] = videoData;
        [userCreatedVideo saveEventually];
        
    }];
}

- (void)removeVideo:(Video *)video
{
    PFQuery *query = [PFQuery queryWithClassName:@"UserCreatedVideo"];
    
    // Retrieve the object by id
    [query getObjectInBackgroundWithId:video.parseID block:^(PFObject *userCreatedVideo, NSError *error) {
        [userCreatedVideo deleteInBackground];
        
    }];
}

@end
