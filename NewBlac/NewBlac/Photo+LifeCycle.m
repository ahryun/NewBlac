//
//  Photo+LifeCycle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/5/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Photo+LifeCycle.h"
#import "PhotoCorners+LifeCycle.h"
#import "Video+LifeCycle.h"

@implementation Photo (LifeCycle)

+ (Photo *)photoWithOriginalPhoto:(UIImage *)originalPhoto withCroppedPhoto:(UIImage *)croppedPhoto withCoordinates:(NSArray *)coordinates withApertureSize:(float)apertureSize withFocalLength:(float)focalLength ifCornersDetected:(BOOL)cornersDetected
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    Photo *photo = [Photo MR_createInContext:context];
    NSData *originalPhotoData = UIImageJPEGRepresentation(originalPhoto, 0);
    NSData *croppedPhotoData = UIImageJPEGRepresentation(croppedPhoto, 0);
    [photo setOriginalPhoto:originalPhotoData];
    [photo setCroppedPhoto:croppedPhotoData];
    [photo setTimeTaken:[NSDate date]];
    [photo setApertureSize:[NSNumber numberWithFloat:apertureSize]];
    [photo setFocalLength:[NSNumber numberWithFloat:focalLength]];
    [photo setCornersDetected:[NSNumber numberWithBool:cornersDetected]];
    PhotoCorners *photoCorners = [PhotoCorners photoCorners:coordinates];
    [photo setCanvasRect:photoCorners];
    
    [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"An error occurred while trying to save context %@", error);
    }];
    
    return photo;
}

+ (void)deletePhoto:(Photo *)photo
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    [photo MR_deleteInContext:context];
    [photo.video updateAllPhotoIndexInVideo];
    
    [context MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"An error occurred while trying to save context %@", error);
    }];
}

@end
