//
//  TakeImageViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/2/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "TakeImageViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>
#import "StillImagePreview.h"
#import "Canvas.h"
//#import "ViewImageViewController.h"
#import "SharedManagedDocument.h"
#import "Photo+LifeCycle.h"
#import "UIImage+ResizeImage.h"

static void *CapturingStillImageContext = &CapturingStillImageContext;
static void *RecordingContext = &RecordingContext;
static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface TakeImageViewController ()

@property (nonatomic, weak) IBOutlet StillImagePreview *stillImagePreview;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) UIView *snapshotView;
@property (weak, nonatomic) IBOutlet UIButton *cancelCamera;
@property (weak, nonatomic) IBOutlet UIImageView *customActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *instructionLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameNumberLabel;
@property (nonatomic, strong) Photo *photo;
@property (nonatomic) Canvas *canvas;
@property (nonatomic, strong) UIImage *croppedImage;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) id runtimeErrorHandlingObserver;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;

@end

@implementation TakeImageViewController

- (UIImage *)croppedImage
{
    if (!_croppedImage) _croppedImage = [[UIImage alloc] init];
    return _croppedImage;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.managedObjectContext = [NSManagedObjectContext MR_defaultContext];

	// Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetPhoto;
	[self setSession:session];
	
	// Setup the preview view
	[self.stillImagePreview setSession:session];
	
	// Check for device authorization
	[self checkDeviceAuthorizationStatus];
    
    // Hide the status bar
    [self prefersStatusBarHidden];
    
    // Draw the black overlay view
    [self drawBlackOverlay];

	// Dispatch the rest of session setup to the sessionQueue so that the main queue isn't blocked.
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];
	
    __weak typeof(self) weakSelf = self;
	dispatch_async(sessionQueue, ^{
        typeof(self) strongSelf = weakSelf;
		[strongSelf setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		AVCaptureDevice *videoDevice = [TakeImageViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error) NSLog(@"%@", error);
		if ([session canAddInput:videoDeviceInput]) {
			[session addInput:videoDeviceInput];
			[strongSelf setVideoDeviceInput:videoDeviceInput];
		}
		
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput]) {
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			[strongSelf setStillImageOutput:stillImageOutput];
		}
	});
}

- (void)drawBlackOverlay
{
    UIView *baseView = [[UIView alloc] initWithFrame:self.view.bounds];
    //self.view = baseView;
    [self.view insertSubview:baseView belowSubview:self.buttonsView];
    [baseView setBackgroundColor:[UIColor blackColor]];
    baseView.userInteractionEnabled = NO;
    baseView.alpha = 0.6;
    
    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.frame = baseView.layer.bounds;
    CGRect biggerRect = CGRectMake(mask.frame.origin.x, mask.frame.origin.y, mask.frame.size.width, mask.frame.size.height);
    CGRect smallerRect = CGRectMake(30.0f, 30.0f, baseView.frame.size.width - (30.0f * 2), baseView.frame.size.height - (30.0f * 2));
    
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMinY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMaxY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(biggerRect), CGRectGetMaxY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(biggerRect), CGRectGetMinY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMinY(biggerRect))];
    
    [maskPath moveToPoint:CGPointMake(CGRectGetMinX(smallerRect), CGRectGetMinY(smallerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(smallerRect), CGRectGetMaxY(smallerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(smallerRect), CGRectGetMaxY(smallerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(smallerRect), CGRectGetMinY(smallerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(smallerRect), CGRectGetMinY(smallerRect))];
    
    mask.path = maskPath.CGPath;
    [mask setFillRule:kCAFillRuleEvenOdd];
    mask.fillColor = [[UIColor blackColor] CGColor];
    baseView.layer.mask = mask;
    
    // If photos object is created before coming into the Camera mode, take off "+1"
    NSString *frameCountString = [NSString stringWithFormat:NSLocalizedString(@"frame %i", @"It tells the user which frame number she's on while taking a photo"), [self.video.photos count] + 1];
    [self.frameNumberLabel setText:[frameCountString uppercaseString]];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *tapString = NSLocalizedString(@"tap anywhere", @"Instruction to tell the user to tap anywhere on the screen to take a photo");
    self.instructionLabel.text = [tapString uppercaseString];
    
    __weak typeof(self) weakSelf = self;
	dispatch_async(self.sessionQueue, ^{
        typeof(self) strongSelf = weakSelf;
		[strongSelf addObserver:strongSelf forKeyPath:@"sessionRunningAndDeviceAuthorized"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:SessionRunningAndDeviceAuthorizedContext];
		[strongSelf addObserver:strongSelf forKeyPath:@"stillImageOutput.capturingStillImage"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:CapturingStillImageContext];
		[[NSNotificationCenter defaultCenter] addObserver:strongSelf
                                                 selector:@selector(subjectAreaDidChange:)
                                                     name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                   object:[[strongSelf videoDeviceInput] device]];
		
        __weak typeof(self) weakSelf = self;
		[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[strongSelf session] queue:nil usingBlock:^(NSNotification *note) {
			typeof(self) strongSelf = weakSelf;
			dispatch_async([strongSelf sessionQueue], ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[strongSelf.session startRunning];
			});
		}]];
		[[self session] startRunning];
	});
}

- (void)viewDidDisappear:(BOOL)animated
{
    __weak typeof(self) weakSelf = self;
	dispatch_async(self.sessionQueue, ^{
        typeof(self) strongSelf = weakSelf;
		[strongSelf.session stopRunning];
		
		[[NSNotificationCenter defaultCenter] removeObserver:strongSelf name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[strongSelf.videoDeviceInput device]];
		[[NSNotificationCenter defaultCenter] removeObserver:strongSelf.runtimeErrorHandlingObserver];
		
		[strongSelf removeObserver:strongSelf forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
		[strongSelf removeObserver:strongSelf forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
	});
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Main Functions
- (IBAction)takeStillImage:(UIGestureRecognizer *)gestureRecognizer
{
    // Let the user know that the photo is being processed
    [self showLoadingBar];
    if ([self.video.photos count] < MAX_PHOTO_COUNT_PER_VIDEO) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.sessionQueue, ^{
            typeof(self) strongSelf = weakSelf;
            // Update the orientation on the still image output video connection before capturing.
            [[strongSelf.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[strongSelf.stillImagePreview layer] connection] videoOrientation]];
            
            // Capture a still image.
            [strongSelf.stillImageOutput captureStillImageAsynchronouslyFromConnection:[strongSelf.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                // Creates exifAttachments
                CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer,
                                                                  kCGImagePropertyExifDictionary,
                                                                  NULL);
                // Print out EXIF data
                exifAttachments? NSLog(@"attachements: %@", exifAttachments): NSLog(@"no attachments");
                
                if (imageDataSampleBuffer) {
                    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                    UIImage *image = [[UIImage alloc] initWithData:imageData];
                    NSLog(@"image width is %f, height is %f", image.size.width, image.size.height);
                    image = [UIImage imageWithImage:image scaledToMultiplier:0.5];
                    NSLog(@"image width is %f, height is %f", image.size.width, image.size.height);
                    float focalLength = [[(__bridge NSDictionary *)exifAttachments valueForKey:@"FocalLength"] floatValue];
                    float apertureSize = [[(__bridge NSDictionary *)exifAttachments valueForKey:@"FNumber"] floatValue];
                    
                    NSLog(@"FocalLength is %f and FNumber is %f\n", focalLength, apertureSize);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        typeof(self) strongSelf = weakSelf;
                        float aspectRatio = !strongSelf.video.screenRatio ? 0 : [strongSelf.video.screenRatio floatValue];
                        strongSelf.canvas = [[Canvas alloc] initWithPhoto:image withFocalLength:focalLength withApertureSize:apertureSize withAspectRatio:aspectRatio];
                        [strongSelf.canvas straightenCanvas];
                        strongSelf.croppedImage = strongSelf.canvas.originalImage;
                        // Photo entity is created in core data with paths to original photo, cropped photo and coordinate.
                        [strongSelf.video setScreenRatio:[NSNumber numberWithFloat:strongSelf.canvas.screenAspect]];
                        strongSelf.photo = [Photo photoWithOriginalPhoto:image
                                                  withCroppedPhoto:strongSelf.croppedImage
                                                   withCoordinates:strongSelf.canvas.coordinates
                                                  withApertureSize:apertureSize
                                                   withFocalLength:focalLength
                                                 ifCornersDetected:strongSelf.canvas.cornersDetected];
                        
                        // Think about whether it's right to put a filter here. App crashes if more than 75 photos are added to a single video.8
                        // If, for some freak reason, the user was able to get into this view when there are 75 frames in this video, video fails to add the video and if fails the photo gets deleted. Worst case scenario.
                        BOOL success = [strongSelf.video addPhotosObjectWithAuthentification:strongSelf.photo];
                        if (!success) [Photo deletePhoto:strongSelf.photo];
//                        [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//                            if (error) NSLog(@"An error occurred while trying to save context %@", error);
//                        }];
                        
                        [strongSelf performSegueWithIdentifier:@"Add Image To Video" sender:self];
                    });
                }
            }];
        });
    }
}

- (void)showLoadingBar
{
    NSString *creatingFrameString = NSLocalizedString(@"creating frame", @"Telling the user that the frame is being generated");
    self.instructionLabel.text = [creatingFrameString uppercaseString];
    UIView *snapShot = [self.view resizableSnapshotViewFromRect:self.view.frame afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    snapShot.frame = self.view.frame;
    [self.view insertSubview:snapShot belowSubview:self.customActivityIndicator];
    self.snapshotView = snapShot;
    [self.customActivityIndicator setHidden:NO];
    [self rotateLayerInfinite:self.customActivityIndicator.layer];
}

- (void)rotateLayerInfinite:(CALayer *)layer
{
    CABasicAnimation *rotation;
    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = [NSNumber numberWithFloat:0];
    rotation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
    rotation.duration = 0.7f; // Speed
    rotation.repeatCount = HUGE_VALF; // Repeat forever. Can be a finite number.
    [layer removeAllAnimations];
    [layer addAnimation:rotation forKey:@"Spin"];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode
       exposeWithMode:(AVCaptureExposureMode)exposureMode
        atDevicePoint:(CGPoint)point
monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    __weak typeof(self) weakSelf = self;
	dispatch_async([self sessionQueue], ^{
        typeof(self) strongSelf = weakSelf;
		AVCaptureDevice *device = [[strongSelf videoDeviceInput] device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) {
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		} else {
			NSLog(@"%@", error);
		}
	});
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus
         exposeWithMode:AVCaptureExposureModeContinuousAutoExposure
          atDevicePoint:devicePoint
monitorSubjectAreaChange:NO];
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			captureDevice = device;
			break;
		}
	}
	return captureDevice;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == CapturingStillImageContext) {
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		if (isCapturingStillImage) [self runStillImageCaptureAnimation];
	} else if (context == SessionRunningAndDeviceAuthorizedContext) {
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
        __weak typeof(self) weakSelf = self;
		dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
			if (isRunning) {
				[strongSelf.cancelCamera setEnabled:YES];
			} else {
				[strongSelf.cancelCamera setEnabled:NO];
			}
		});
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)runStillImageCaptureAnimation
{
    __weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
		[[strongSelf.stillImagePreview layer] setOpacity:0.0];
		[UIView animateWithDuration:.25 animations:^{
			[[strongSelf.stillImagePreview layer] setOpacity:1.0];
		}];
	});
}

- (BOOL)isSessionRunningAndDeviceAuthorized
{
	return [self.session isRunning] && self.isDeviceAuthorized;
}

- (void)checkDeviceAuthorizationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted) {
			//Granted access to mediaType
			[self setDeviceAuthorized:YES];
		} else {
			//Not granted access to mediaType
            __weak typeof(self) weakSelf = self;
			dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) strongSelf = weakSelf;
                NSString *okString = NSLocalizedString(@"ok", @"Action button to acknowledge what's been said");
				[[[UIAlertView alloc] initWithTitle:@"Pieces"
											message:NSLocalizedString(@"Pieces doesn't have permission to use Camera, please change privacy settings", @"Ask the user to change the privacy settings to permit camera use")
										   delegate:strongSelf
								  cancelButtonTitle:[okString uppercaseString]
								  otherButtonTitles:nil] show];
				[strongSelf setDeviceAuthorized:NO];
			});
		}
	}];
}

#pragma mark - Outlet Actions

- (IBAction)toggleFlash:(UIButton *)sender
{
    if (sender.selected) {
        [sender setSelected:NO];
        [self toogleFlashWithState:AVCaptureTorchModeOff];
    } else {
        [sender setSelected:YES];
        [self toogleFlashWithState:AVCaptureTorchModeOn];
    };
}

-(void)toogleFlashWithState:(AVCaptureTorchMode)torchMode
{
    if ([[self.videoDeviceInput device] hasTorch] && [self.videoDeviceInput device].torchAvailable) {
        [[self.videoDeviceInput device] lockForConfiguration:nil];
        [[self.videoDeviceInput device] setTorchMode:torchMode];
        [[self.videoDeviceInput device] unlockForConfiguration];
    }
}

@end
