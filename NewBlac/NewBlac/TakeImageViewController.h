//
//  TakeImageViewController.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/2/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Video+LifeCycle.h"

@interface TakeImageViewController : UIViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) Video *video;

@end
