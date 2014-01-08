//
//  EditImageViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/6/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "EditImageViewController.h"
#import "CornerDetectionView.h"
#import "PhotoCorners+LifeCycle.h"

@interface EditImageViewController () <CornerDetectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *originalImageView;
@property (strong, nonatomic) IBOutlet CornerDetectionView *cornerDetectionView;


@end

@implementation EditImageViewController

- (void)setPhoto:(Photo *)photo
{
    // Need to change to Core Data
    _photo = photo;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Sets the controller as a delegate for CornerDetectionView
    self.cornerDetectionView.delegate = self;
    [self displayPhoto];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)displayPhoto
{
    // Need to get the core data photo and get the photo path and convert the photo in file system to UIImage
    if (self.photo) {
        NSData *photoData = [NSData dataWithContentsOfFile:self.photo.originalPhotoFilePath];
        self.originalImageView.image = [UIImage imageWithData:photoData];
        self.originalImageView.frame = CGRectMake(0, 0,
                                                 self.originalImageView.image.size.width,
                                                 self.originalImageView.image.size.height);
    }
}

- (void)displayCorners
{
    // Display 4 corners
    if (self.photo) {
        [NSArray arrayWithObjects:self.photo.canvasRect.bottomLeftx, self.photo.canvasRect.bottomLefty];
    }
    
}


@end
