//
//  Photo+LifeCycle.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/5/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Photo.h"

@interface Photo (LifeCycle)

+ (Photo *)photoWithOriginalPhotoFilePath:(NSString *)path withCroppedPhotoFilePath:(NSString *)croppedPath withCoordinates:(NSArray *)coordinates inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSString *)saveUIImage:(UIImage *)image toFilePath:(NSString *)imgPath;
+ (void)deletePhoto:(Photo *)photo inContext:(NSManagedObjectContext *)context;

@end
