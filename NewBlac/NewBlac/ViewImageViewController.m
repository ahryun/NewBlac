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
}

- (void)displayPhoto
{
    if (self.photo) {
        NSLog(@"Image exists and the image size is %f x %f\n", self.photo.size.width, self.photo.size.height);
        // image is a UIImage init alloced with NSData
        self.croppedImageView.image = self.photo;
        self.croppedImageView.frame = CGRectMake(0, 0, self.photo.size.width, self.photo.size.height);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSLog(@"I'm in view did load\n");
    [self displayPhoto];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
