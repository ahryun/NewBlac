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

+ (Photo *)photoWithOriginalPhoto:(UIImage *)originalPhoto withCroppedPhoto:(UIImage *)croppedPhoto withCoordinates:(NSArray *)coordinates withApertureSize:(float)apertureSize withFocalLength:(float)focalLength ifCornersDetected:(BOOL)cornersDetected inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    NSData *originalPhotoData = UIImageJPEGRepresentation(originalPhoto, 0);
    NSData *croppedPhotoData = UIImageJPEGRepresentation(croppedPhoto, 0);
    photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
    [photo setOriginalPhoto:originalPhotoData];
    [photo setCroppedPhoto:croppedPhotoData];
    [photo setTimeTaken:[NSDate date]];
    [photo setApertureSize:[NSNumber numberWithFloat:apertureSize]];
    [photo setFocalLength:[NSNumber numberWithFloat:focalLength]];
    [photo setCornersDetected:[NSNumber numberWithBool:cornersDetected]];
    PhotoCorners *photoCorners = [PhotoCorners photoCorners:coordinates withManagedObjectContext:context];
    [photo setCanvasRect:photoCorners];
    
    NSError *error;
    [context save:&error];
    
    return photo;
}

+ (void)deletePhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context
{
    [context deleteObject:photo];
    [photo.video updateAllPhotoIndexInVideo];
    
    NSError *error;
    [context save:&error];
}

@end
