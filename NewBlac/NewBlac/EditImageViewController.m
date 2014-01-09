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
@property (weak, nonatomic) IBOutlet CornerDetectionView *cornerDetectionView;

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
    //[self displayPhoto];
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

#pragma mark CornerDetectionView
- (void)displayCorners
{
    // Display 4 corners
    if (self.photo) {
        self.cornerDetectionView.bottomLeftCorner = [NSArray arrayWithObjects:self.photo.canvasRect.bottomLeftxPercent, self.photo.canvasRect.bottomLeftyPercent, nil];
        self.cornerDetectionView.bottomRightCorner = [NSArray arrayWithObjects:self.photo.canvasRect.bottomRightxPercent, self.photo.canvasRect.bottomRightyPercent, nil];
        self.cornerDetectionView.topLeftCorner = [NSArray arrayWithObjects:self.photo.canvasRect.topLeftxPercent, self.photo.canvasRect.topLeftyPercent, nil];
        self.cornerDetectionView.topRightCorner = [NSArray arrayWithObjects:self.photo.canvasRect.topRightxPercent, self.photo.canvasRect.topRightyPercent, nil];
    }
    
}

#pragma mark Memory Management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"View did disappear\n");
    self.view = nil;
}


@end
