//
//  ShareSocialViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/18/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "ShareSocialViewController.h"
#import <Parse/Parse.h>

@interface ShareSocialViewController ()

@property (weak, nonatomic) IBOutlet UIView *shareButtonsView;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *photoAlbumButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) CALayer *loadingCircleLayer;
@property (nonatomic) int retryCount;

@end

@implementation ShareSocialViewController

#pragma mark - View Life Cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.snapShotView.layer.opacity = 0.3;
    [self.view addSubview:self.snapShotView];
    [self.view insertSubview:self.snapShotView belowSubview:self.shareButtonsView];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.shareButtonsView setAlpha:1.0];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *cancelString = NSLocalizedString(@"cancel", @"Action button to cancel action or modal");
    [self.cancelButton setTitle:[cancelString uppercaseString] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - FACEBOOK
- (IBAction)publishToFacebook:(id)sender
{
    if ([self.video.photos count] / [self.video.framesPerSecond integerValue] >= 1) {
        self.retryCount = 0;
        [self loadShareButton:self.facebookButton];
        
        // Check for publish permissions
        [FBRequestConnection startWithGraphPath:@"/me/permissions"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  if (!error){
                                      NSDictionary *permissions= [(NSArray *)[result data] objectAtIndex:0];
                                      if (![permissions objectForKey:@"publish_actions"]){
                                          // Publish permissions not found, ask for publish_actions
                                          [self requestPublishPermissions];
                                      } else {
                                          // Publish permissions found, publish the OG story
                                          [self publishStory];
                                      }
                                      
                                  } else {
                                      // There was an error, handle it
                                      [self handleAuthError:error];
                                  }
                              }];
    } else {
        UIAlertView *videoTooShortAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add more frames", @"Warning to the user that the video is too short") message:NSLocalizedString(@"Facebook does not allow uploading videos shorter than 1 second", @"Definition of short") delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [videoTooShortAlert show];
    }
}

#pragma mark - Facebook API calls
- (void)requestPublishPermissions
{
    NSString *okString = NSLocalizedString(@"ok", @"Action button to acknowledge what's been said");
    // Request publish_actions
    [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                          defaultAudience:FBSessionDefaultAudienceFriends
                                        completionHandler:^(FBSession *session, NSError *error) {
                                            __block NSString *alertText;
                                            __block NSString *alertTitle;
                                            if (!error) {
                                                if ([FBSession.activeSession.permissions
                                                     indexOfObject:@"publish_actions"] == NSNotFound){
                                                    // Permission not granted, tell the user we will not publish
                                                    alertTitle = NSLocalizedString(@"Permission not granted", @"Warning to the user that she did not grant this app a permission to post to her Facebook account");
                                                    alertText = NSLocalizedString(@"Your action will not be published to Facebook.", @"It explains to the user that her work will not be published to Facebook as she did not grant this app a permission");
                                                    [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                                message:alertText
                                                                               delegate:self
                                                                      cancelButtonTitle:[okString uppercaseString]
                                                                      otherButtonTitles:nil] show];
                                                    [self resetFacebookButton];
                                                } else {
                                                    // Permission granted, publish the OG story
                                                    [self publishStory];
                                                }
                                                
                                            } else {
                                                // There was an error, handle it
                                                [self handleRequestPermissionError:error];
                                            }
                                        }];
}

- (void)publishStory
{
    NSError *dataError;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.video.compFilePath]) {
        NSData *videoData = [NSData dataWithContentsOfFile:self.video.compFilePath options:
                             NSDataReadingMappedAlways error:&dataError];
        NSString *title = @"";
        NSString *description = @"";
        
        if (description == nil) description = @"";
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys: videoData, @"video.mov", @"video/quicktime", @"contentType", title, @"title", description, @"description", nil];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [FBRequestConnection startWithGraphPath:@"/me/videos" parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                if (result) {
                    [self.managedObjectContext performBlock:^{
                        [self.video setFacebookVideoID:[result objectForKey:@"id"]];
                        [self resetFacebookButton];
                        [self dismissSelf];
                    }];
                }
            } else {
                [self handleAPICallError:error];
            }
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        }];
    }
}

#pragma mark - Facebook Error Handling
- (void)handleAuthError:(NSError *)error
{
    [self resetFacebookButton];
    
    NSString *alertText;
    NSString *alertTitle;
    
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        // Error requires people using you app to make an action outside your app to recover
        alertTitle = NSLocalizedString(@"Something went wrong", @"Alert message to the user that there was an error in connecting to Facebook");
        alertText = [FBErrorUtility userMessageForError:error];
        [self showMessage:alertText withTitle:alertTitle];
        
    } else {
        // You need to find more information to handle the error within your app
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            //The user refused to log in into your app, either ignore or...
//            alertTitle = @"Login cancelled";
//            alertText = @"You need to login to access this part of the app";
//            [self showMessage:alertText withTitle:alertTitle];
            
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            // We need to handle session closures that happen outside of the app
//            alertTitle = @"Session Error";
//            alertText = @"Your current session is no longer valid. Please log in again.";
//            [self showMessage:alertText withTitle:alertTitle];
            
        } else {
            // All other errors that can happen need retries
            // Show the user a generic error message
            alertTitle = NSLocalizedString(@"Something went wrong", @"Alert message to the user that there was an error in connecting to Facebook");
            alertText = NSLocalizedString(@"Please retry", @"Ask the user to log in again");
            [self showMessage:alertText withTitle:alertTitle];
        }
    }
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    NSString *okString = NSLocalizedString(@"ok", @"Action button to acknowledge what's been said");
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:[okString uppercaseString]
                      otherButtonTitles:nil] show];
}

// Helper method to handle errors during permissions request
- (void)handleRequestPermissionError:(NSError *)error
{
    [self resetFacebookButton];
    
    NSString *alertText;
    NSString *alertTitle;
    
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        // Error requires people using an app to make an out-of-band action to recover
        alertTitle = NSLocalizedString(@"Something went wrong", @"Alert message to the user that there was an error in connecting to Facebook");
        alertText = [FBErrorUtility userMessageForError:error];
        [self showMessage:alertText withTitle:alertTitle];
        
    } else {
        // We need to handle the error
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            // Ignore it or...
            alertTitle = NSLocalizedString(@"Permission not granted", @"Warning to the user that she did not grant this app a permission to post to her Facebook account");;
            alertText = NSLocalizedString(@"Your action will not be published to Facebook.", @"It explains to the user that her work will not be published to Facebook as she did not grant this app a permission");
            [self showMessage:alertText withTitle:alertTitle];
            
        } else{
            // All other errors that can happen need retries
            // Show the user a generic error message
            alertTitle = NSLocalizedString(@"Something went wrong", @"Alert message to the user that there was an error in connecting to Facebook");
            alertText = NSLocalizedString(@"Please retry", @"Ask the user to log in again");
            [self showMessage:alertText withTitle:alertTitle];
        }   
    }
}

// Helper method to handle errors during API calls
- (void)handleAPICallError:(NSError *)error
{
    [self resetFacebookButton];
    // If the user has removed a permission that was previously granted
    if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryPermissions) {
        NSLog(@"Re-requesting permissions");
        // Ask for required permissions.
        [self requestPublishPermissions];
        return;
    }
    
    // Some Graph API errors need retries, we will have a simple retry policy of one additional attempt
    // We also retry on a throttling error message, a more sophisticated app should consider a back-off period
    self.retryCount++;
    if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryRetry ||
        [FBErrorUtility errorCategoryForError:error] == FBErrorCategoryThrottling) {
        if (self.retryCount < 2) {
            NSLog(@"Retrying open graph post");
            // Recovery tactic: Call API again.
            [self publishStory];
            return;
        } else {
            NSLog(@"Retry count exceeded.");
            return;
        }
    }
    
    // For all other errors...
    NSString *alertText;
    NSString *alertTitle;
    
    // Get more error information from the error
    NSInteger errorCode = error.code;
    NSDictionary *errorInformation = [[[[error userInfo] objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"]
                                       objectForKey:@"body"]
                                      objectForKey:@"error"];
    NSInteger errorSubcode = 0;
    if ([errorInformation objectForKey:@"code"]){
        errorSubcode = [[errorInformation objectForKey:@"code"] integerValue];
    }
    
    // Check if it's a "duplicate action" error
    if (errorCode == 5 && errorSubcode == 3501) {
        // Tell the user the action failed because duplicate action-object  are not allowed
//        alertTitle = @"Duplicate action";
//        alertText = @"You already did this, you can perform this action only once on each item.";
        alertTitle = NSLocalizedString(@"Something went wrong", @"Alert message to the user that there was an error in connecting to Facebook");
        alertText = NSLocalizedString(@"Please try again later.", @"Ask the user to retry at a later time");
        
        // If the user should be notified, we show them the corresponding message
    } else if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = NSLocalizedString(@"Something went wrong", @"Alert message to the user that there was an error in connecting to Facebook");
        alertText = [FBErrorUtility userMessageForError:error];
        
    } else {
        // show a generic error message
        NSLog(@"Unexpected error posting to open graph: %@", error);
        alertTitle = NSLocalizedString(@"Something went wrong", @"Alert message to the user that there was an error in connecting to Facebook");
        alertText = NSLocalizedString(@"Please try again later.", @"Ask the user to retry at a later time");
    }
    [self showMessage:alertText withTitle:alertTitle];
}

#pragma mark - PHOTOALBUM
- (IBAction)saveToPhotoalbum:(UIButton *)sender
{
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.video.compFilePath)) {
        [self loadShareButton:sender];
        UISaveVideoAtPathToSavedPhotosAlbum(self.video.compFilePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *) contextInfo
{
    if (error) {
        NSString *okString = NSLocalizedString(@"ok", @"Action button to acknowledge what's been said");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Cannot save to the camera roll" delegate:self cancelButtonTitle:[okString uppercaseString] otherButtonTitles:nil];
        [alertView show];
    } else {
        [self resetPhotoalbumButton];
        [self dismissSelf];
    }
}

#pragma mark - Support Functions
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


- (IBAction)dismissModal:(UIButton *)sender
{
    [self dismissSelf];
}

- (void)dismissSelf
{
//    [self resetFacebookButton];
    [UIView animateWithDuration:0.5f animations:^{
        self.shareButtonsView.layer.opacity = 0.f;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:^{
            NSLog(@"Modal has been dismissed\n");
        }];
    }];
}

- (void)loadShareButton:(UIButton *)button
{
    // Make all buttons disabled
    [button setSelected:NO];
    for (UIButton *button in self.shareButtonsView.subviews) {
        [button setEnabled:NO];
    }
    
    CALayer *loadingCircle = [CALayer layer];
    loadingCircle.contents = (id)[UIImage imageNamed:@"ShareLoadingButton"].CGImage;
    loadingCircle.frame = CGRectInset(button.bounds, -2.f, -2.f);
    loadingCircle.opacity = 0.f;
    self.loadingCircleLayer = loadingCircle;
    [button.layer addSublayer:loadingCircle];
    [UIView animateWithDuration:0.5f animations:^{
        loadingCircle.opacity = 1.f;
    } completion:^(BOOL finished) {
        [self rotateLayerInfinite:loadingCircle];
    }];
}

- (void)resetFacebookButton
{
    // Make all buttons disabled
    [self.facebookButton setSelected:YES];
    for (UIButton *button in self.shareButtonsView.subviews) {
        [button setEnabled:YES];
    }
    if (self.loadingCircleLayer) [self.loadingCircleLayer removeFromSuperlayer];
}

- (void)resetPhotoalbumButton
{
    [self.photoAlbumButton setSelected:YES];
    for (UIButton *button in self.shareButtonsView.subviews) {
        [button setEnabled:YES];
    }
    if (self.loadingCircleLayer) [self.loadingCircleLayer removeFromSuperlayer];
}

@end
