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
#import <QuartzCore/QuartzCore.h>

@interface EditImageViewController () <CornerDetectionViewDelegate>

@property (weak, nonatomic) UIImageView *originalImageView;
@property (weak, nonatomic) CALayer *zoomLayer;
@property (weak, nonatomic) CornerDetectionView *cornerDetectionView;
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (nonatomic, strong) NSMutableArray *corners;
@property (nonatomic, assign) NSUInteger selectedCornerIndex;
@property (nonatomic, strong) CornerCircle *selectedCorner;
@property (nonatomic, strong) NSMutableArray *coordinates;
@property (nonatomic) BOOL coordinatesChanged;
@property (weak, nonatomic) IBOutlet UIImageView *loupeView;
@property (nonatomic) CGPoint loupeLocation;

@end

#define ZOOM_FACTOR 4.0
#define LOUPE_BEZEL_WIDTH 18.0

@implementation EditImageViewController

- (IBAction)doneEditingImage:(UIButton *)sender {
    
    // See if the coordinates have changed
    if (self.coordinatesChanged) {
        // Update the corner coordinates in core data
        [self.photo.canvasRect photoCorners:self.coordinates];
        
        // Send the new coordinates to the c++ file to recalculate the matrix
        UIImage *originalImage = [UIImage imageWithData:self.photo.originalPhoto];
        BOOL isFirstImage = [self.video.photos count] > 0 ? NO : YES;
        [self.canvas unskewWithCoordinates:self.coordinates withOriginalImage:originalImage ifFirstImage:isFirstImage];
        
        [self.video setScreenRatio:[NSNumber numberWithFloat:self.canvas.screenAspect]];
        
        // Replace the cropped image saved in core data
        NSData *imageData = UIImageJPEGRepresentation(self.canvas.originalImage, 1.0);
        [self.photo setCroppedPhoto:imageData];
    }
    
    // May need to prepareForSegue
    [self performSegueWithIdentifier:@"Unwind Done Editing Image" sender:self];
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

#pragma mark - View Lifecycle
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
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
    self.originalImageView.userInteractionEnabled = YES;
    [self.originalImageView addGestureRecognizer:panGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.buttonView.opaque = NO;
    [self.buttonView setBackgroundColor:[UIColor clearColor]];
}

- (void)viewDidLayoutSubviews
{
    CALayer *contentLayer = [CALayer layer];
    contentLayer.frame = self.loupeView.bounds;
    contentLayer.backgroundColor = [[UIColor blackColor] CGColor];
    
    // The content layer has a circular mask applied.
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = contentLayer.bounds;
    
    CGMutablePathRef circlePath = CGPathCreateMutable();
    CGPathAddEllipseInRect(circlePath, NULL, CGRectInset(self.loupeView.layer.bounds, LOUPE_BEZEL_WIDTH , LOUPE_BEZEL_WIDTH));
    
    maskLayer.path = circlePath;
    CGPathRelease(circlePath);
    contentLayer.mask = maskLayer;
    
    // Set up the zoom AVPlayerLayer.
    CGSize zoomSize = CGSizeMake(self.originalImageView.frame.size.width * ZOOM_FACTOR, self.originalImageView.frame.size.height * ZOOM_FACTOR);
    CALayer *zoomLayer = [CALayer layer];
    NSLog(@"Zoom size width is %f and height is %f\n", zoomSize.width, zoomSize.height);
    zoomLayer.frame = CGRectMake((contentLayer.bounds.size.width /2) - (zoomSize.width /2),
                                      (contentLayer.bounds.size.height /2) - (zoomSize.height /2),
                                      zoomSize.width,
                                      zoomSize.height);
    UIImage *originalImage = [UIImage imageWithData:self.photo.originalPhoto];
    zoomLayer.contents = (id)originalImage.CGImage;
    zoomLayer.contentsGravity = kCAGravityResizeAspectFill;
    [contentLayer addSublayer:zoomLayer];
    self.zoomLayer = zoomLayer;
    [self.loupeView.layer addSublayer:contentLayer];
    
    // Four corners layer
    CALayer *cornersLayer = [CALayer layer];
    cornersLayer.frame = self.zoomLayer.frame;
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
        UIImage *image = [UIImage imageWithData:self.photo.originalPhoto];
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

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.view = nil;
    self.originalImageView = nil;
    self.cornerDetectionView = nil;
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches began\n");
    [self.nextResponder touchesBegan:touches withEvent:event];
    if ([touches count] > 1) {
        return;
    } else if ([touches count] == 1) {
        CGPoint touchPoint = [[touches anyObject] locationInView:self.originalImageView];
        float viewWidth = self.view.frame.size.width;
        float offset = 30.0;
        float loupeWidth = self.loupeView.frame.size.width;
        CGPoint loupeLocation = touchPoint.x <= viewWidth / 2 ? CGPointMake(viewWidth - loupeWidth - offset, offset) : CGPointMake(offset, offset);
        self.loupeLocation = loupeLocation;
        [self.loupeView setFrame:CGRectMake(loupeLocation.x, loupeLocation.y, self.loupeView.frame.size.width, self.loupeView.frame.size.height)];
        [self.loupeView setHidden:NO];
        self.zoomLayer.position = CGPointMake((self.originalImageView.center.x - touchPoint.x) * ZOOM_FACTOR,
                                              (self.originalImageView.center.y - touchPoint.y) * ZOOM_FACTOR);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches ended\n");
    [self.loupeView setHidden:YES];
}

- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer
{
    NSLog(@"Pan recognizer state is %i\n", panRecognizer.state);
    switch (panRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSLog(@"Pan began\n");
            CGPoint tapLocation = [panRecognizer locationInView:self.originalImageView];
            self.selectedCornerIndex = [self hitTest:tapLocation];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            NSLog(@"Pan changed\n");
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
            
            // Loupe
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.zoomLayer.position = CGPointMake(self.zoomLayer.position.x - translation.x * ZOOM_FACTOR,
                                                  self.zoomLayer.position.y - translation.y * ZOOM_FACTOR);
            [CATransaction commit];

        }
        case UIGestureRecognizerStateEnded: {
            // Pan gesture state ended is called multiple times even though I still have a finger on the screen
            // So I check how many fingers I have on the screen
            if (panRecognizer.numberOfTouches < 1) [self.loupeView setHidden:YES];
            NSLog(@"Number of touches is %lu\n", (unsigned long)panRecognizer.numberOfTouches);
            NSLog(@"Pan ended\n");
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
