//
//  EditImageViewController.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/6/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+LifeCycle.h"
#import "Canvas.h"
#import "Video+LifeCycle.h"

@protocol EditImageViewControllerDelegate;

@interface EditImageViewController : UIViewController {
    id<EditImageViewControllerDelegate> delegate;
}

@property (nonatomic, strong) id<EditImageViewControllerDelegate> delegate;
@property (nonatomic, strong) Photo *photo;
@property (nonatomic, strong) Canvas *canvas;
@property (nonatomic, strong) Video *video;

@end

@protocol EditImageViewControllerDelegate <NSObject>

- (void)popEditImageViewController:(EditImageViewController *)viewController;

@end

