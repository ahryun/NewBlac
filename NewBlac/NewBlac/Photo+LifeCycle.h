//
//  Photo+LifeCycle.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/5/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "Photo.h"

@interface Photo (LifeCycle)

+ (Photo *)photoWithOriginalPhotoFilePath:(NSString *)path withCoordinates:(NSArray *)coordinates inManagedObjectContext:(NSManagedObjectContext *)context;

@end
