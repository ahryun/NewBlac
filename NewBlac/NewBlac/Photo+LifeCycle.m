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

+ (Photo *)photoWithOriginalPhotoFilePath:(NSString *)path withCoordinates:(NSArray *)coordinates inManagedObjectContext:(NSManagedObjectContext *)context
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
        [photo setCroppedPhotoFilePath:[path stringByAppendingString:@"_cropped"]];
        PhotoCorners *photoCorners = [PhotoCorners photoCorners:coordinates withManagedObjectContext:context];
        [photo setCanvasRect:photoCorners];
    } else {
        photo = [matches lastObject];
    }
    
    return photo;
}

@end
