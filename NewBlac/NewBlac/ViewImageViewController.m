//
//  ViewImageViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/2/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "ViewImageViewController.h"

@interface ViewImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *croppedImageView;

@end

@implementation ViewImageViewController

- (void)setPhoto:(UIImage *)photo
{
    _photo = photo;
    [self displayPhoto:photo];
}

- (void)displayPhoto:(UIImage *)image
{
    if (image) {
        NSLog(@"Image exists and the image size is %f x %f\n", image.size.width, image.size.height);
        // image is a UIImage init alloced with NSData
        self.croppedImageView.image = image;
        self.croppedImageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
