//
//  blacViewController.m
//  Blac
//
//  Created by Ahryun Moon on 11/20/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "NewBlacViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Canvas.h"

@interface NewBlacViewController ()

@property (nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *takePictureButton;
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) UIImage *capturedImage;
@property (nonatomic) BOOL cameraReady;
@property (strong, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (strong, nonatomic) Canvas *canvas;

@end

@implementation NewBlacViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraIsReady:)
                                                 name:AVCaptureSessionDidStartRunningNotification
                                               object:nil];
    self.cameraReady = NO;
}

- (void)cameraIsReady:(NSNotification *)notification {
    self.cameraReady = YES;
}

//- (IBAction)showImagePickerForCamera:(id)sender
//{
//    NSString *ifStillImage = (NSString *)kUTTypeImage;
//    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//        if ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:ifStillImage]) {
//            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
//        }
//        
//    }
//    if (self.previewView) {
//        [self.previewView removeFromSuperview];
//    }
//}
//
//
//- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
//{
//    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
//    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
//    imagePickerController.sourceType = sourceType;
//    imagePickerController.delegate = self;
//    imagePickerController.allowsEditing = NO;
//    
//    if (sourceType == UIImagePickerControllerSourceTypeCamera)
//    {
//        /*
//         The user wants to use the camera interface. Set up our custom overlay view for the camera.
//         */
//        imagePickerController.showsCameraControls = NO;
//        
//        /*
//         Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
//         */
//        [[NSBundle mainBundle] loadNibNamed:@"overlayView" owner:self options:nil];
//        self.overlayView.frame = imagePickerController.cameraOverlayView.frame;
//        imagePickerController.cameraOverlayView = self.overlayView;
//        self.overlayView = nil;
//    }
//    
//    self.imagePickerController = imagePickerController;
//    [self presentViewController:self.imagePickerController animated:NO completion:nil];
//}
//- (IBAction)takePhoto:(UIButton *)sender
//{
//    if (self.cameraReady) {
//        [self.imagePickerController takePicture];
//    }
//    self.cameraReady = NO;
//}
//
//- (IBAction)done:(UIButton *)sender
//{
//    [self finishAndUpdate];
//}
//
//- (void)showPreview
//{
//    [[NSBundle mainBundle] loadNibNamed:@"previewView" owner:self options:nil];
//    [self.view addSubview:self.previewView];
//    [self.previewImage setImage:self.capturedImage];
//}
//
//- (IBAction)saveAndReturn:(UIButton *)sender
//{
//    [self.previewView removeFromSuperview];
//}
//
//- (void)finishAndUpdate
//{
//    [self dismissViewControllerAnimated:NO completion:NULL];
//    self.imagePickerController = nil;
//}

#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//{
//    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
//    float focalLength = [[[[info valueForKey:UIImagePickerControllerMediaMetadata]
//                           valueForKey:@"{Exif}"]
//                          valueForKey:@"FocalLength"] floatValue];
//    NSString *deviceModel = [[NSString alloc] init];
//    deviceModel = [[[info valueForKey:UIImagePickerControllerMediaMetadata]
//                         valueForKey:@"{TIFF}"]
//                        valueForKey:@"Model"];
//    
//    // Do something to the photo
//    [self createCanvasWithPhoto:image withFocalLength:focalLength withModel:deviceModel];
//    
//    self.capturedImage = self.canvas.originalImage;
//    
//    // Add the unwarped image to AVAssetWriterInput
//    
//    [self finishAndUpdate];
//    [self showPreview];
//}
//
//- (void)createCanvasWithPhoto:(UIImage *)photo withFocalLength:(float)focalLength withModel:(NSString *)deviceModel
//{
//    self.canvas = [[Canvas alloc] init];
//    [self.canvas setPhoto: photo];
//    [self.canvas setOriginalImage: photo];
//    [self.canvas setImageWidth:photo.size.width];
//    [self.canvas setImageHeight:photo.size.height];
//    [self.canvas setFocalLength:focalLength];
//    [self.canvas setDeviceModel:[deviceModel lowercaseString]]; // change to aperture size
//    
//    NSLog(@"%@", [deviceModel lowercaseString]);
//    
//    [self.canvas straightenCanvas];
//}
//
//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
//{
//    [self dismissViewControllerAnimated:YES completion:NULL];
//}
//
//- (IBAction)cancelPhoto:(UIStoryboardSegue *)segue
//{
//    
//}

@end
