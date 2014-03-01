//
//  Photo+LifeCycle.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/5/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Photo.h"

@interface Photo (LifeCycle)

+ (Photo *)photoWithOriginalPhoto:(UIImage *)originalPhoto withCroppedPhoto:(UIImage *)croppedPhoto withCoordinates:(NSArray *)coordinates withApertureSize:(float)apertureSize
                  withFocalLength:(float)focalLength inManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)deletePhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context;

@end
