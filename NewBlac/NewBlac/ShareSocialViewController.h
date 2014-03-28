//
//  ShareSocialViewController.h
//  NewBlac
//
//  Created by Ahryun Moon on 3/18/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Video+LifeCycle.h"

@protocol ShareModalViewDelegate;

@interface ShareSocialViewController : UIViewController

//@property (nonatomic) id<ShareModalViewDelegate> delegate;
@property (nonatomic, strong) UIView *snapShotView;
@property (nonatomic, strong) Video *video;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

//@protocol ShareModalViewDelegate <NSObject>
//
//- (void)dismissShareModalViewDelegate:(ShareSocialViewController *)view;
//
//@end
