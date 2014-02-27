//
//  blacViewController.h
//  Blac
//
//  Created by Ahryun Moon on 11/20/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

//#import <UIKit/UIKit.h>
//#import <AVFoundation/AVFoundation.h>
#import "Video+LifeCycle.h"
#import "CoreDataCollectionViewController.h"

@interface FramesCollectionViewController : CoreDataCollectionViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) Video *video;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
