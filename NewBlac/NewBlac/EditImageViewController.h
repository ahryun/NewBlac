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


@interface EditImageViewController : UIViewController

@property (nonatomic, strong) Photo *photo;
@property (nonatomic, strong) Canvas *canvas;

@end
