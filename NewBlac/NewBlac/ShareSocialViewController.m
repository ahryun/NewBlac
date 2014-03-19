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

@end

@implementation ShareSocialViewController

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)publishToFacebook:(id)sender
{
    CALayer *loadingCircle = [CALayer layer];
    loadingCircle.contents = (id)[UIImage imageNamed:@"ShareLoadingButton"].CGImage;
    loadingCircle.frame = CGRectInset(self.facebookButton.bounds, -2.f, -2.f);
    [self.facebookButton.layer addSublayer:loadingCircle];
    [self rotateLayerInfinite:loadingCircle];
    [self.facebookButton setEnabled:NO];
    
    NSError *dataError;
    NSData *videoData = [NSData dataWithContentsOfFile:self.video.compFilePath options:
                         NSDataReadingMappedAlways error:&dataError];
    
    NSString *description = @"something";
    NSString *title = @"video title";
    
    if (description == nil) description = @"";
    [PFFacebookUtils reauthorizeUser:[PFUser currentUser]
              withPublishPermissions:@[@"publish_stream"]
                            audience:FBSessionDefaultAudienceFriends
                               block:^(BOOL succeeded, NSError *error) {
                                   if (succeeded) {
                                       NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys: videoData, @"video.mov", @"video/quicktime", @"contentType", title, @"title", description, @"description", nil];
                                       [FBRequestConnection startWithGraphPath:@"/me/videos" parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                           if (error) {
                                               UIAlertView *loadingFailedAlert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"The video didn't upload correctly" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"", nil];
                                                [loadingFailedAlert show]; } else {
                                            if (result) {
                                                [self.managedObjectContext performBlockAndWait:^{
                                                [self.video setFacebookVideoID:[result objectForKey:@"id"]];
                                                 }];
                                             }
                                             
                                             [self dismissSelf];
                                         }
                                         [self.facebookButton setEnabled:YES];
                                         [loadingCircle removeFromSuperlayer];
                                     }];
                                   }
                               }];
    
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


- (IBAction)dismissModal:(UIButton *)sender
{
    [self dismissSelf];
}

- (void)dismissSelf
{
    [self dismissViewControllerAnimated:NO completion:^{
        NSLog(@"Modal has been dismissed\n");
    }];
}


@end
