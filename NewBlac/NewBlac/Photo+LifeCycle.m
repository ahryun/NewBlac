//
//  Photo+LifeCycle.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/5/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Photo+LifeCycle.h"
#import "PhotoCorners+LifeCycle.h"

@implementation Photo (LifeCycle)

+ (Photo *)photoWithOriginalPhotoFilePath:(NSString *)path withCroppedPhotoFilePath:(NSString *)croppedPath withCoordinates:(NSArray *)coordinates inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeTaken" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"originalPhotoFilePath = %@", path];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || [matches count] > 1) {
        // Handle error
    } else if (![matches count]) {
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        [photo setOriginalPhotoFilePath:path];
        [photo setCroppedPhotoFilePath:croppedPath];
        [photo setTimeTaken:[NSDate date]];
        PhotoCorners *photoCorners = [PhotoCorners photoCorners:coordinates withManagedObjectContext:context];
        [photo setCanvasRect:photoCorners];
    } else {
        photo = [matches lastObject];
    }
    
    return photo;
}

+ (NSString *)saveUIImage:(UIImage *)image toFilePath:(NSString *)imgPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (!imgPath) {
        NSString *UUID = [[NSUUID UUID] UUIDString];
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath =[documentPaths objectAtIndex:0];
        NSString *originalImageDir = [documentPath stringByAppendingPathComponent:@"Images"];
#warning Configure attributes for image encryption
        NSDictionary *fileProtectionAttributes = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
        
        [fileManager createDirectoryAtPath:originalImageDir withIntermediateDirectories:YES attributes:nil error:nil];
        imgPath = [originalImageDir stringByAppendingPathComponent:UUID];
    }
    
    NSString *imgPathWithFormat = [imgPath stringByAppendingString:@".jpg"];
    if (![fileManager fileExistsAtPath:imgPathWithFormat]) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        BOOL success = [fileManager createFileAtPath:imgPathWithFormat contents:imageData attributes:nil];
        if (!success) NSLog(@"Photo did NOT get saved correctly");
    } else {
        NSLog(@"File exists. Possibly UUID collision. This should never happen.\n");
    }
    return imgPath;
}

+ (void)deletePhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    
    [fileManager removeItemAtPath:photo.originalPhotoFilePath error:&error];
    [fileManager removeItemAtPath:photo.croppedPhotoFilePath error:&error];
    [context deleteObject:photo];
}



@end
