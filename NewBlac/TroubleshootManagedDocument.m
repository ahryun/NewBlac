//
//  TroubleshootManagedDocument.m
//  FlickrCD
//
//  Created by Ahryun Moon on 11/11/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "TroubleshootManagedDocument.h"

@implementation TroubleshootManagedDocument

// Prints to console whenever Core Data gets saved
- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSLog(@"Auto-Saving Document");
    return [super contentsForType:typeName error:outError];
}

// Handle error with Core Data
- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    NSLog(@"UIManagedDocument error: %@", error.localizedDescription);
    NSArray* errors = [[error userInfo] valueForKey:NSLocalizedFailureReasonErrorKey];
    if(errors != nil && errors.count > 0) {
        for (NSError *error in errors) {
            NSLog(@"  Error: %@", error.userInfo);
        }
    } else {
        NSLog(@"  %@", error.userInfo);
    }
}

@end