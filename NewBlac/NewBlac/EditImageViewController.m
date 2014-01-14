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

@property (weak, nonatomic) UIImageView *originalImageView;
@property (weak, nonatomic) CornerDetectionView *cornerDetectionView;
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (nonatomic, strong) NSMutableArray *corners;
@property (nonatomic, assign) NSUInteger selectedCornerIndex;
@property (nonatomic, strong) CornerCircle *selectedCorner;

@end

@implementation EditImageViewController

- (void)setPhoto:(Photo *)photo
{
    // Need to change to Core Data
    _photo = photo;
}

@synthesize selectedCornerIndex = _selectedCornerIndex;

- (void)setSelectedCornerIndex:(NSUInteger)selectedCornerIndex
{
    CGRect oldSelectionBounds = CGRectZero;
    if (_selectedCornerIndex < [self.corners count]) {
        oldSelectionBounds = self.selectedCorner.totalBounds;
    }
    _selectedCornerIndex = (selectedCornerIndex > [self.corners count]) ? NSNotFound : selectedCornerIndex;
    CGRect newSelectionBounds = self.selectedCorner.totalBounds;
    CGRect rectToRedraw = CGRectUnion(oldSelectionBounds, newSelectionBounds);
    [self.cornerDetectionView setNeedsDisplayInRect:rectToRedraw];
}

- (CornerCircle *)selectedCorner
{
    if (self.selectedCornerIndex == NSNotFound) {
        return nil;
    }
    return [self.corners objectAtIndex:self.selectedCornerIndex];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedCornerIndex = NSNotFound;
    // Sets the controller as a delegate for CornerDetectionView
    [self displayPhoto];
    [self displayCorners];
    self.cornerDetectionView.delegate = self;
    [self.cornerDetectionView reloadData];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    [tapGesture setNumberOfTapsRequired:1];
    self.originalImageView.userInteractionEnabled = YES;
    [self.originalImageView addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.buttonView.opaque = NO;
    [self.buttonView setBackgroundColor:[UIColor clearColor]];
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
        
        UIImage *image = [UIImage imageWithData:photoData];
        float widthRatio = self.view.bounds.size.width / image.size.width;
        float heightRatio = self.view.bounds.size.height / image.size.height;
        float scale = MIN(widthRatio, heightRatio);
        float imageWidth = scale * image.size.width;
        float imageHeight = scale * image.size.height;
        float xOffset = (self.view.bounds.size.width - imageWidth) / 2;
        float yOffset = (self.view.bounds.size.height - imageHeight) / 2;
        
        CGRect rect = CGRectMake(xOffset, yOffset, imageWidth, imageHeight);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = image;
        imageView.opaque = NO;
        [self.view insertSubview:imageView belowSubview:self.buttonView];
        self.originalImageView = imageView;
        
        NSLog(@"Image view frame is %f x %f", self.view.frame.size.width, self.view.frame.size.height);
        NSLog(@"Image view bounds is %f x %f", self.view.bounds.size.width, self.view.bounds.size.height);
        
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
    CornerDetectionView *cornerDetectionview = [[CornerDetectionView alloc] initWithFrame:self.originalImageView.bounds];
    for (NSArray *coordinate in coordinates) {
        CornerCircle *corner = [CornerCircle addCornerWithCoordinate:coordinate inRect:cornerDetectionview.bounds.size];
        [self.corners addObject:corner];
    }
    cornerDetectionview.opaque = NO;
    [self.originalImageView addSubview:cornerDetectionview];
    self.cornerDetectionView = cornerDetectionview;
    NSLog(@"displayCorners has been called");
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

/* Delete the following two functions */
- (UIBezierPath *)drawTaptargetInView:(CornerDetectionView *)view atIndex:(NSUInteger)index
{
    CornerCircle *corner = [self.corners objectAtIndex:index];
    return corner.tapTarget;
}

- (UIColor *)fillTapColorInView:(CornerDetectionView *)view
{
    return [UIColor yellowColor];
}
/* Delete the above two functions */

#pragma mark Memory Management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.view = nil;
    self.originalImageView = nil;
    self.cornerDetectionView = nil;
}

#pragma mark - Touch handling

- (void)tapDetected:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint tapLocation = [tapRecognizer locationInView:self.originalImageView];
    self.selectedCornerIndex = [self hitTest:tapLocation];
    NSLog(@"The tap location is %f, %f", tapLocation.x, tapLocation.y);
    NSLog(@"The corner selected is %u", self.selectedCornerIndex);
}

#pragma mark - Hit Testing

- (NSUInteger)hitTest:(CGPoint)point
{
    __block NSUInteger hitCornerIndex = NSNotFound;
    [self.corners enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id corner, NSUInteger idx, BOOL *stop) {
        if ([corner containsPoint:point]) {
            hitCornerIndex = idx;
            *stop = YES;
        }
    }];
    return hitCornerIndex;
}


@end
