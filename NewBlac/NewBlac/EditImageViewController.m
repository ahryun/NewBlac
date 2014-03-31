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
#import "Strings.h"

@interface EditImageViewController () <CornerDetectionViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) UIImageView *originalImageView;
@property (weak, nonatomic) CALayer *zoomLayer;
@property (weak, nonatomic) CornerDetectionView *cornerDetectionView;
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (nonatomic, strong) NSMutableArray *corners;
@property (nonatomic, assign) NSUInteger selectedCornerIndex;
@property (nonatomic, strong) CornerCircle *selectedCorner;
@property (nonatomic, strong) NSMutableArray *coordinates;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL coordinatesChanged;
@property (weak, nonatomic) IBOutlet UIImageView *loupeView;
@property (weak, nonatomic) IBOutlet UIImageView *loupeCenter;
@property (nonatomic) CGPoint loupeLocation;
@property (nonatomic) UIBezierPath *maskPath;
@property (nonatomic) UIView *baseView;
@property (nonatomic) CAShapeLayer *mask;

@end

@implementation EditImageViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.managedObjectContext = [NSManagedObjectContext MR_defaultContext];

    // Add imageView
    UIImageView *imageView = [[UIImageView alloc] init];
    [self.view insertSubview:imageView belowSubview:self.buttonView];
    self.originalImageView = imageView;
    self.selectedCornerIndex = NSNotFound;
    self.coordinatesChanged = NO;
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // ViewDidLayoutSubviews is called twice and thus calling my setup call twice.
    // This is a hackish way to fix that.
    if (!self.cornerDetectionView) [self setup];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.view = nil;
    self.originalImageView = nil;
    self.cornerDetectionView = nil;
}

- (void)setup
{
    // Sets the controller as a delegate for CornerDetectionView
    [self displayPhoto];
    [self displayCorners];
    self.cornerDetectionView.delegate = self;
    [self.cornerDetectionView reloadData];
    
    NSLog(@"View frame is %f x %f", self.view.frame.size.width, self.view.frame.size.height);
    
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
    CGSize zoomSize = CGSizeMake(CGRectGetWidth(self.originalImageView.bounds) * ZOOM_FACTOR, CGRectGetHeight(self.originalImageView.bounds) * ZOOM_FACTOR);
    CALayer *zoomLayer = [CALayer layer];
    NSLog(@"Zoom size width is %f and height is %f\n", zoomSize.width, zoomSize.height);
    zoomLayer.frame = CGRectMake(0, 0,
                                 zoomSize.width,
                                 zoomSize.height);
    UIImage *originalImage = [UIImage imageWithData:self.photo.originalPhoto];
    NSMutableDictionary *noImplicitAnimation = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position", [NSNull null], @"anchorPoint", nil];
    zoomLayer.actions = noImplicitAnimation;
    zoomLayer.position = CGPointMake(self.loupeView.frame.size.width / 2, self.loupeView.frame.size.height / 2);
    zoomLayer.contents = (id)originalImage.CGImage;
    zoomLayer.contentsGravity = kCAGravityResizeAspectFill;
    [contentLayer addSublayer:zoomLayer];
    self.zoomLayer = zoomLayer;
    [self.loupeView.layer addSublayer:contentLayer];
    
    // Four corners layer
    CALayer *cornersLayer = [CALayer layer];
    cornersLayer.frame = self.zoomLayer.frame;
    
    UIView *baseView = [[UIView alloc] initWithFrame:self.originalImageView.bounds];
    [self.originalImageView insertSubview:baseView belowSubview:self.cornerDetectionView];
    [baseView setBackgroundColor:[UIColor blackColor]];
    baseView.userInteractionEnabled = NO;
    baseView.alpha = 0.5;
    
    [self drawBlackOverlay];
    
    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.frame = baseView.layer.bounds;
    mask.path = self.maskPath.CGPath;
    [mask setFillRule:kCAFillRuleEvenOdd];
    mask.fillColor = [[UIColor blackColor] CGColor];
    baseView.layer.mask = mask;
    self.mask = mask;
    self.baseView = baseView;
}

- (void)drawBlackOverlay
{
    CGFloat imageViewWidth = self.originalImageView.frame.size.width;
    CGFloat imageViewHeight = self.originalImageView.frame.size.height;
    CGRect biggerRect = CGRectMake(0, 0, imageViewWidth, imageViewHeight);
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMinY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMaxY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(biggerRect), CGRectGetMaxY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(biggerRect), CGRectGetMinY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMinY(biggerRect))];
    
    [maskPath moveToPoint:CGPointMake((CGFloat)[[self.coordinates objectAtIndex:2][0] floatValue] * imageViewWidth, (CGFloat)[[self.coordinates objectAtIndex:2][1] floatValue] * imageViewHeight)];
    [maskPath addLineToPoint:CGPointMake((CGFloat)[[self.coordinates objectAtIndex:3][0] floatValue] * imageViewWidth, (CGFloat)[[self.coordinates objectAtIndex:3][1] floatValue] * imageViewHeight)];
    [maskPath addLineToPoint:CGPointMake((CGFloat)[[self.coordinates objectAtIndex:1][0] floatValue] * imageViewWidth, (CGFloat)[[self.coordinates objectAtIndex:1][1] floatValue] * imageViewHeight)];
    [maskPath addLineToPoint:CGPointMake((CGFloat)[[self.coordinates objectAtIndex:0][0] floatValue] * imageViewWidth, (CGFloat)[[self.coordinates objectAtIndex:0][1] floatValue] * imageViewHeight)];
    [maskPath closePath];
    
    self.maskPath = maskPath;
    self.mask.path = maskPath.CGPath;
    self.baseView.layer.mask = self.mask;
    [self.baseView setNeedsDisplay];
}

- (void)displayPhoto
{
    // Need to get the core data photo and get the photo path and convert the photo in file system to UIImage
    if (self.photo) {
        UIImage *image = [UIImage imageWithData:self.photo.originalPhoto];
        CGFloat viewRatio = self.view.bounds.size.width / self.view.bounds.size.height;
        CGFloat imageRatio = image.size.width / image.size.height;
        CGFloat imageWidth = 0.f;
        CGFloat imageHeight = 0.f;
        if (viewRatio < imageRatio) {
            imageWidth = self.view.bounds.size.width;
            imageHeight = imageWidth / imageRatio;
        } else {
            imageHeight = self.view.bounds.size.height;
            imageWidth = imageHeight * imageRatio;
        }
        CGFloat xOffset = (self.view.bounds.size.width - imageWidth) / 2;
        CGFloat yOffset = (self.view.bounds.size.height - imageHeight) / 2;
        
        self.originalImageView.frame = CGRectMake(xOffset, yOffset, imageWidth, imageHeight);
        self.originalImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.originalImageView.image = image;
        self.originalImageView.opaque = NO;
    }
}

#pragma mark - Storyboard Actions
- (IBAction)backButtonPressed:(UIBarButtonItem *)sender
{
    if (self.coordinatesChanged) {
        NSString *cancelString = NSLocalizedString(@"cancel", @"Action button to cancel action or modal");
        NSString *yesString = NSLocalizedString(@"yes", @"Action word to confirm leaving without saving");
        UIAlertView *saveBeforeLeavingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Go back without saving?", @"Ask the user if she wants to leave the screen without saving the changes she's made") message:@"" delegate:self cancelButtonTitle:[cancelString capitalizedString] otherButtonTitles:[yesString capitalizedString], nil];
        [saveBeforeLeavingAlert show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex]) {
        NSLog(@"Cancel index is %li", (long)buttonIndex);
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)doneEditingImage:(UIBarButtonItem *)sender
{
    [self saveBeforeLeaving];
}

- (void)saveBeforeLeaving
{
    if (self.coordinatesChanged) {
        // Update the corner coordinates in core data
        [self.photo.canvasRect setCoordinates:self.coordinates];
        
        // Send the new coordinates to the c++ file to recalculate the matrix
        UIImage *originalImage = [UIImage imageWithData:self.photo.originalPhoto];
        BOOL isFirstImage = [self.video.photos count] > 0 ? NO : YES;
        [self.canvas unskewWithCoordinates:self.coordinates withOriginalImage:originalImage ifFirstImage:isFirstImage];
        
        [self.video setScreenRatio:[NSNumber numberWithFloat:self.canvas.screenAspect]];
        // Replace the cropped image saved in core data
        NSData *imageData = UIImageJPEGRepresentation(self.canvas.originalImage, 1.0);
        [self.photo setCroppedPhoto:imageData];
        [self.photo setCornersDetected:[NSNumber numberWithBool:YES]];
        [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"An error occurred while trying to save context %@", error);
        }];
        
        [self performSegueWithIdentifier:@"Unwind Done Editing Image" sender:self];
    } else {
        [self performSegueWithIdentifier:@"Unwind Done Editing Image" sender:self];
    }
}

#pragma mark CornerDetectionView
- (void)displayCorners
{
    if ([self.photo.cornersDetected boolValue]) {
        self.coordinates = [NSMutableArray arrayWithObjects:
                            [NSMutableArray arrayWithObjects:self.photo.canvasRect.bottomLeftxPercent, self.photo.canvasRect.bottomLeftyPercent, nil],
                            [NSMutableArray arrayWithObjects:self.photo.canvasRect.bottomRightxPercent, self.photo.canvasRect.bottomRightyPercent, nil],
                            [NSMutableArray arrayWithObjects:self.photo.canvasRect.topLeftxPercent, self.photo.canvasRect.topLeftyPercent, nil],
                            [NSMutableArray arrayWithObjects:self.photo.canvasRect.topRightxPercent, self.photo.canvasRect.topRightyPercent, nil]
                            , nil];
    } else {
        // If corners were not detected and no meaningful coordinates available, I want the corners to appear at designated places.
        self.coordinates = [NSMutableArray arrayWithObjects:
                            [NSMutableArray arrayWithObjects:@0.2f, @0.8f, nil],
                            [NSMutableArray arrayWithObjects:@0.8f, @0.8f, nil],
                            [NSMutableArray arrayWithObjects:@0.2f, @0.2f, nil],
                            [NSMutableArray arrayWithObjects:@0.8f, @0.2f, nil]
                            , nil];
    }
    
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


- (NSMutableArray *)corners
{
    if (!_corners) {
        _corners = [[NSMutableArray alloc] init];
    }
    return _corners;
}

#pragma mark - CornerDetectionView delegate

- (UIBezierPath *)drawPathInView:(CornerDetectionView *)view atIndex:(NSUInteger)index
{
    CornerCircle *corner = [self.corners objectAtIndex:index];
    return corner.path;
}

- (UIColor *)fillColorInView:(CornerDetectionView *)view
{
    return [UIColor colorWithRed:(240.f/255) green:(101.f/255) blue:(98.f/255) alpha:1.f];
}

- (NSUInteger)numberOfCornersInView:(CornerDetectionView *)view
{
    return [self.corners count];
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches began\n");
    [self.nextResponder touchesBegan:touches withEvent:event];
    if ([touches count] > 1) {
        return;
    } else if ([touches count] == 1) {
        CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
        CGPoint touchPointInImageView = [self.originalImageView convertPoint:touchPoint fromView:self.view];
        
        self.selectedCornerIndex = [self hitTest:touchPointInImageView];
        
        if (self.selectedCornerIndex != NSNotFound) {
            CGFloat viewWidth = self.view.frame.size.width;
            CGFloat offset = 20.0;
            CGFloat loupeWidth = self.loupeView.frame.size.width;
            CGFloat loupeHeight = self.loupeView.frame.size.height;
            CGPoint loupeLocation = touchPoint.x <= viewWidth / 2 ? CGPointMake(viewWidth - loupeWidth - offset, offset) : CGPointMake(offset, offset);
            self.loupeLocation = loupeLocation;
            [self.loupeView setFrame:CGRectMake(loupeLocation.x, loupeLocation.y, loupeWidth, loupeHeight)];
            [self.loupeCenter setFrame:self.loupeView.frame];
            [self changeZoomLayerAnchorPoint];
            [self showLoupe];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches ended\n");
    [self hideLoupe];
}

- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer
{
    switch (panRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSLog(@"Pan began\n");
            break;
        }
        case UIGestureRecognizerStateChanged: {
            NSLog(@"Pan changed\n");
            
            if (self.selectedCornerIndex != NSNotFound) {
                CGPoint translation = [panRecognizer translationInView:self.originalImageView];
                CGRect originalBounds = self.selectedCorner.totalBounds;
                CGRect newBounds = CGRectApplyAffineTransform(originalBounds, CGAffineTransformMakeTranslation(translation.x, translation.y));
                CGRect rectToRedraw = CGRectUnion(originalBounds, newBounds);
                
                [self.selectedCorner moveBy:translation];
                [self.cornerDetectionView reloadDataInRect:rectToRedraw];
                [panRecognizer setTranslation:CGPointZero inView:self.originalImageView];
                
                // At least one corner has changed its position
                self.coordinatesChanged = YES;
                
                // Update coordinates of the corner selected
                [[self.coordinates objectAtIndex:self.selectedCornerIndex] replaceObjectAtIndex:0 withObject:[[NSNumber alloc] initWithFloat:self.selectedCorner.centerPoint.x / self.originalImageView.bounds.size.width]];
                [[self.coordinates objectAtIndex:self.selectedCornerIndex] replaceObjectAtIndex:1 withObject:[[NSNumber alloc] initWithFloat:self.selectedCorner.centerPoint.y / self.originalImageView.bounds.size.height]];
                
                [self drawBlackOverlay];
                
                // Loupe
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                [self changeZoomLayerAnchorPoint];
                [CATransaction commit];
            }
        }
        case UIGestureRecognizerStateEnded: {
            // Pan gesture state ended is called multiple times even though I still have a finger on the screen
            // So I check how many fingers I have on the screen
            if (panRecognizer.numberOfTouches < 1 && !self.loupeView.hidden) [self hideLoupe];
            NSLog(@"Number of touches is %lu\n", (unsigned long)panRecognizer.numberOfTouches);
            NSLog(@"Pan ended\n");
        }
        default:
            break;
    }
}

- (void)showLoupe
{
    [self.loupeView setHidden:NO];
    [self.loupeCenter setHidden:NO];
}

- (void)hideLoupe
{
    [self.loupeView setHidden:YES];
    [self.loupeCenter setHidden:YES];
}

- (void)changeZoomLayerAnchorPoint
{
    // Calculate the translation between the position and loupe center point
    CGPoint newAnchorPoint = CGPointMake([[self.coordinates objectAtIndex:self.selectedCornerIndex][0] floatValue], [[self.coordinates objectAtIndex:self.selectedCornerIndex][1] floatValue]);
    self.zoomLayer.anchorPoint = newAnchorPoint;
}

#pragma mark - Hit Testing

- (NSUInteger)hitTest:(CGPoint)point
{
    __block NSUInteger hitCornerIndex = NSNotFound;
    [self.corners enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id corner, NSUInteger idx, BOOL *stop) {
        if ([corner containsPoint:point]) {
            hitCornerIndex = idx;
            NSLog(@"Corner index is %lu", (unsigned long)hitCornerIndex);
            *stop = YES;
        }
    }];
    return hitCornerIndex;
}


@end
