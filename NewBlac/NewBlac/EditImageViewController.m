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
#import "CornerCircle.h"

@interface EditImageViewController () <CornerDetectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *originalImageView;
@property (weak, nonatomic) IBOutlet CornerDetectionView *cornerDetectionView;
@property (nonatomic, strong) NSMutableArray *corners;
@property (nonatomic, assign) NSUInteger selectedShapeIndex;


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
    
    [self displayCorners];
    [self.cornerDetectionView reloadData];
}

- (NSMutableArray *)corners
{
    if (!_corners) {
        _corners = [[NSMutableArray alloc] init];
    }
    return _corners;
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
        
        // This is how it should be changed
//        NSData *photoData = [NSData dataWithContentsOfFile:self.photo.originalPhotoFilePath];
//        
//        self.originalImageView.image = [UIImage imageWithData:photoData];
//        float width = self.originalImageView.image.size.width;
//        float height = self.originalImageView.image.size.height;
//        float offset = 0;
//        if (width > height) {
//            height = self.view.bounds.size.width / width * height;
//            width = self.view.bounds.size.width;
//            offset = (self.view.bounds.size.height - height) / 2;
//            self.originalImageView.frame = CGRectMake(0, offset, width, height);
//        } else {
//            width = self.view.bounds.size.height / height * width;
//            height = self.view.bounds.size.height;
//            offset = (self.view.bounds.size.width - width) / 2;
//            self.originalImageView.frame = CGRectMake(0, 0, width, height);
//        }
    }
}

#pragma mark CornerDetectionView
- (void)displayCorners
{
    NSArray *coordinates = [NSArray arrayWithObjects:
                            [NSArray arrayWithObjects:self.photo.canvasRect.bottomLeftxPercent, self.photo.canvasRect.bottomLeftyPercent, nil],
                            [NSArray arrayWithObjects:self.photo.canvasRect.bottomRightxPercent, self.photo.canvasRect.bottomRightyPercent, nil],
                            [NSArray arrayWithObjects:self.photo.canvasRect.topLeftxPercent, self.photo.canvasRect.topLeftyPercent, nil],
                            [NSArray arrayWithObjects:self.photo.canvasRect.topRightxPercent, self.photo.canvasRect.topRightyPercent, nil]
                            , nil];
    for (NSArray *coordinate in coordinates) {
        NSLog(@"Corner detection view bounds are %f by %f", self.originalImageView.frame.size.width, self.originalImageView.frame.size.height);
        CornerCircle *corner = [CornerCircle addCornerWithCoordinate:coordinate inRect:self.view.bounds.size];
        [self.corners addObject:corner];
    }    
}

- (UIBezierPath *)drawPathInView:(CornerDetectionView *)view atIndex:(NSUInteger)index
{
    CornerCircle *corner = [self.corners objectAtIndex:index];
    return corner.path;
}

- (UIColor *)fillColorInView:(CornerDetectionView *)view
{
    return [UIColor blueColor];
}

- (NSUInteger)numberOfCornersInView:(CornerDetectionView *)view
{
    return [self.corners count];
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
