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
#import "ViewImageViewController.h"
#import "SharedManagedDocument.h"
#import "Photo+LifeCycle.h"

static void *CapturingStillImageContext = &CapturingStillImageContext;
static void *RecordingContext = &RecordingContext;
static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface TakeImageViewController ()

@property (nonatomic, weak) IBOutlet StillImagePreview *stillImagePreview;
@property (nonatomic, strong) Photo *photo;
@property (weak, nonatomic) IBOutlet UIButton *cancelCamera;
@property (nonatomic) Canvas *canvas;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic) id runtimeErrorHandlingObserver;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;

@property (nonatomic, strong) UIImage *croppedImage;

- (IBAction)takeStillImage:(UIGestureRecognizer *)gestureRecognizer;

@end

@implementation TakeImageViewController

@synthesize croppedImage = _croppedImage;
- (UIImage *)croppedImage
{
    if (!_croppedImage) {
        return [[UIImage alloc] init];
    }
    return _croppedImage;
}

- (void)setCroppedImage:(UIImage *)croppedImage
{
    if (_croppedImage != croppedImage) {
        _croppedImage = croppedImage;
    }
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetPhoto;
	[self setSession:session];
	
	// Setup the preview view
	[self.stillImagePreview setSession:session];
	
//	// Check for device authorization
	[self checkDeviceAuthorizationStatus];
	
	// Dispatch the rest of session setup to the sessionQueue so that the main queue isn't blocked.
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];
	
	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [TakeImageViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:videoDeviceInput])
		{
			[session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
		}
		
		AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
		AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:audioDeviceInput])
		{
			[session addInput:audioDeviceInput];
		}
		
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput])
		{
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			[self setStillImageOutput:stillImageOutput];
		}
	});
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!self.managedObjectContext) [self useDemoDocument];
    
	dispatch_async(self.sessionQueue, ^{
		[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:SessionRunningAndDeviceAuthorizedContext];
		[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:CapturingStillImageContext];
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(subjectAreaDidChange:)
                                                     name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                   object:[[self videoDeviceInput] device]];
		
		__weak TakeImageViewController *weakSelf = self;
		[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
			TakeImageViewController *strongSelf = weakSelf;
			dispatch_async([strongSelf sessionQueue], ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[strongSelf.session startRunning];
			});
		}]];
		[[self session] startRunning];
	});
}

- (void)useDemoDocument
{
    [[SharedManagedDocument sharedInstance] performWithDocument:^(UIManagedDocument *document){
        self.managedObjectContext = document.managedObjectContext;
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
	dispatch_async(self.sessionQueue, ^{
		[self.session stopRunning];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[self.videoDeviceInput device]];
		[[NSNotificationCenter defaultCenter] removeObserver:self.runtimeErrorHandlingObserver];
		
		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
		[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
	});
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)takeStillImage:(UIGestureRecognizer *)gestureRecognizer
{
    dispatch_async(self.sessionQueue, ^{
		// Update the orientation on the still image output video connection before capturing.
		[[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[self.stillImagePreview layer] connection] videoOrientation]];
		
		// Flash set to Auto for Still Capture
		[TakeImageViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[self.videoDeviceInput device]];
		
		// Capture a still image.
		[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
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
                float focalLength = [[(__bridge NSDictionary *)exifAttachments valueForKey:@"FocalLength"] floatValue];
                float apertureSize = [[(__bridge NSDictionary *)exifAttachments valueForKey:@"FNumber"] floatValue];
                
                NSLog(@"FocalLength is %f and FNumber is %f\n", focalLength, apertureSize);
                
                // Save the original image to a file system and save URL to core data
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self createCanvasWithPhoto:image withFocalLength:focalLength withApertureSize:apertureSize];
                    NSString *imagePath, *croppedImagePath;
                    imagePath = [self saveUIImage:image toFilePath:nil];
                    croppedImagePath = [self saveUIImage:self.croppedImage toFilePath:[imagePath stringByAppendingString:@"_cropped"]];
                    [self.managedObjectContext performBlock:^{
                        // Photo entity is created in core data with paths to original photo, cropped photo and coordinate.
                        self.photo = [Photo photoWithOriginalPhotoFilePath:[imagePath stringByAppendingString:@".jpg"]
                                                  withCroppedPhotoFilePath:[croppedImagePath stringByAppendingString:@".jpg"]
                                                           withCoordinates:self.canvas.coordinates
                                                    inManagedObjectContext:self.managedObjectContext];
                        [self performSegueWithIdentifier:@"View Image" sender:self];
                    }];
                });
			}
		}];
	});
}

- (void)createCanvasWithPhoto:(UIImage *)photo withFocalLength:(float)focalLength withApertureSize:(float)apertureSize
{
    self.canvas = [[Canvas alloc] init];
    [self.canvas setPhoto: photo];
    [self.canvas setOriginalImage: photo];
    [self.canvas setImageWidth:photo.size.width];
    [self.canvas setImageHeight:photo.size.height];
    [self.canvas setFocalLength:focalLength];
    [self.canvas setApertureSize:apertureSize];
    
    [self.canvas straightenCanvas];
    
    self.croppedImage = self.canvas.originalImage;
}

- (NSString *)saveUIImage:(UIImage *)image toFilePath:(NSString *)imgPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (!imgPath) {
        NSString *UUID = [[NSUUID UUID] UUIDString];
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath =[documentPaths objectAtIndex:0];
        NSString *originalImageDir = [documentPath stringByAppendingPathComponent:@"Images"];
        [fileManager createDirectoryAtPath:originalImageDir withIntermediateDirectories:YES attributes:nil error:nil];
        imgPath = [originalImageDir stringByAppendingPathComponent:UUID];
    }
    
    NSString *imgPathWithFormat = [imgPath stringByAppendingString:@".jpg"];
    if (![fileManager fileExistsAtPath:imgPathWithFormat]) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        BOOL success = [fileManager createFileAtPath:imgPathWithFormat contents:imageData attributes:nil];
        if (!success) NSLog(@"Photo did NOT get saved correctly");
    } else {
        NSLog(@"File exists. Possibly UUID collision. This should never happen.\n");
    }
    return imgPath;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"View Image"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setPhoto:)]) {
            [segue.destinationViewController performSelector:@selector(setPhoto:) withObject:self.photo];
        }
    }
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode
       exposeWithMode:(AVCaptureExposureMode)exposureMode
        atDevicePoint:(CGPoint)point
monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *device = [[self videoDeviceInput] device];
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

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode
           forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) {
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		} else {
			NSLog(@"%@", error);
		}
	}
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
	if (context == CapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage)
		{
			[self runStillImageCaptureAnimation];
		}
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext)
	{
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRunning) {
				[self.cancelCamera setEnabled:YES];
			} else {
				[self.cancelCamera setEnabled:NO];
			}
		});
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)runStillImageCaptureAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self.stillImagePreview layer] setOpacity:0.0];
		[UIView animateWithDuration:.25 animations:^{
			[[self.stillImagePreview layer] setOpacity:1.0];
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
		if (granted)
		{
			//Granted access to mediaType
			[self setDeviceAuthorized:YES];
		}
		else
		{
			//Not granted access to mediaType
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"NewBlac"
											message:@"NewBlac doesn't have permission to use Camera, please change privacy settings"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				[self setDeviceAuthorized:NO];
			});
		}
	}];
}

- (IBAction)unwindToRetakePhoto:(UIStoryboardSegue *)segue
{
    // Nothing needed here
    [self.managedObjectContext performBlock:^{
        // Photo entity is created in core data with paths to original photo, cropped photo and coordinate.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        [fileManager removeItemAtPath:self.photo.originalPhotoFilePath error:&error];
        [fileManager removeItemAtPath:self.photo.croppedPhotoFilePath error:&error];
        [self.managedObjectContext deleteObject:self.photo];
    }];
}

@end
