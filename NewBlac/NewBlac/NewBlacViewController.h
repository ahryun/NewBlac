//
//  blacViewController.h
//  Blac
//
//  Created by Ahryun Moon on 11/20/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <sys/utsname.h>
#import "SharedManagedDocument.h"
#import "Video+LifeCycle.h"


@interface NewBlacViewController : UIViewController 

@property (nonatomic, strong) Video *video;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
