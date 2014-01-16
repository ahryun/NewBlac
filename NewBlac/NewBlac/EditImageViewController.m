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
@property (nonatomic, strong) NSMutableArray *coordinates;
@property (nonatomic) BOOL coordinatesChanged;

@end

@implementation EditImageViewController

- (IBAction)doneEditingImage:(UIButton *)sender {
    
    // See if the coordinates have changed
    if (self.coordinatesChanged) {
        // Update the corner coordinates in core data
        [self.photo.canvasRect photoCorners:self.coordinates];
        // Send the new coordinates to the c++ file to recalculate the matrix
        UIImage *originalImage = [UIImage imageWithContentsOfFile:self.photo.originalPhotoFilePath];
        [self.canvas unskewWithCoordinates:self.coordinates withOriginalImage:originalImage];
        
        // Replace the cropped image saved in file system
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSData *imageData = UIImageJPEGRepresentation(self.canvas.originalImage, 1.0);
        BOOL removeSucceeded = [fileManager removeItemAtPath:self.photo.croppedPhotoFilePath error:nil];
        if (removeSucceeded) {
            BOOL writeSucceeded = [fileManager createFileAtPath:self.photo.croppedPhotoFilePath contents:imageData attributes:nil];
            writeSucceeded ? NSLog(@"Replacing cropped photo file was a success") : NSLog(@"Hey I couldn't resave the new cropped photo");
        }
    }
    
    // May need to prepareForSegue
    [self performSegueWithIdentifier:@"Unwind Done Editing Image" sender:self];
}

- (void)setPhoto:(Photo *)photo
{
    _photo = photo;
}

- (void)setCanvas:(Canvas *)canvas
{
    _canvas = canvas;
}

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
    if (self.selectedCornerIndex == NSNotFound || self.selectedCornerIndex > [self.corners count]) {
        return nil;
    }
    return [self.corners objectAtIndex:self.selectedCornerIndex];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedCornerIndex = NSNotFound;
    self.coordinatesChanged = NO;
    // Sets the controller as a delegate for CornerDetectionView
    [self displayPhoto];
    [self displayCorners];
    self.cornerDetectionView.delegate = self;
    [self.cornerDetectionView reloadData];
    
    UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressDetected:)];
    self.originalImageView.userInteractionEnabled = YES;
    [self.originalImageView addGestureRecognizer:pressGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
    [self.originalImageView addGestureRecognizer:panGesture];
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
    self.coordinates = [NSMutableArray arrayWithObjects:
                        [NSMutableArray arrayWithObjects:self.photo.canvasRect.bottomLeftxPercent, self.photo.canvasRect.bottomLeftyPercent, nil],
                        [NSMutableArray arrayWithObjects:self.photo.canvasRect.bottomRightxPercent, self.photo.canvasRect.bottomRightyPercent, nil],
                        [NSMutableArray arrayWithObjects:self.photo.canvasRect.topLeftxPercent, self.photo.canvasRect.topLeftyPercent, nil],
                        [NSMutableArray arrayWithObjects:self.photo.canvasRect.topRightxPercent, self.photo.canvasRect.topRightyPercent, nil]
                        , nil];
    CornerDetectionView *cornerDetectionview = [[CornerDetectionView alloc] initWithFrame:self.originalImageView.bounds];
    for (NSArray *coordinate in self.coordinates) {
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

- (void)pressDetected:(UILongPressGestureRecognizer *)pressGesture
{
    CGPoint touchLocation = [pressGesture locationInView:self.originalImageView];
    self.selectedCornerIndex = [self hitTest:touchLocation];
    NSLog(@"The tap location is %f, %f", touchLocation.x, touchLocation.y);
    NSLog(@"The corner selected is %u", self.selectedCornerIndex);
}

- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer
{
    switch (panRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSLog(@"Pan began");
            CGPoint tapLocation = [panRecognizer locationInView:self.originalImageView];
            self.selectedCornerIndex = [self hitTest:tapLocation];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            NSLog(@"Pan changed");
            CGPoint translation = [panRecognizer translationInView:self.originalImageView];
            CGRect originalBounds = self.selectedCorner.totalBounds;
            CGRect newBounds = CGRectApplyAffineTransform(originalBounds, CGAffineTransformMakeTranslation(translation.x, translation.y));
            CGRect rectToRedraw = CGRectUnion(originalBounds, newBounds);
            
            if (self.selectedCorner) {
                [self.selectedCorner moveBy:translation];
                [self.cornerDetectionView reloadDataInRect:rectToRedraw];
                [panRecognizer setTranslation:CGPointZero inView:self.originalImageView];
                
                // At least one corner has changed its position
                self.coordinatesChanged = YES;
                
                // Update coordinates of the corner selected
                [[self.coordinates objectAtIndex:self.selectedCornerIndex] replaceObjectAtIndex:0 withObject:[[NSNumber alloc] initWithFloat:self.selectedCorner.centerPoint.x / self.originalImageView.bounds.size.width]];
                [[self.coordinates objectAtIndex:self.selectedCornerIndex] replaceObjectAtIndex:1 withObject:[[NSNumber alloc] initWithFloat:self.selectedCorner.centerPoint.y / self.originalImageView.bounds.size.height]];
            }
        }
        default:
            break;
    }
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
