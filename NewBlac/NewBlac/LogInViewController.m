//
//  LogInViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/13/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "LogInViewController.h"
#import <Parse/Parse.h>

@interface LogInViewController ()

@property (nonatomic) BOOL loggedIn;
@property (weak, nonatomic) IBOutlet UIButton *dismissModalButton;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *mainInstruction;
@property (weak, nonatomic) IBOutlet UILabel *subInstruction;
@property (weak, nonatomic) IBOutlet UIButton *logInOrOutButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingFBLogin;
@property (weak, nonatomic) CALayer *logoutButtonLayer;

@end

@implementation LogInViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prefersStatusBarHidden];
    [self.loadingFBLogin stopAnimating];

    if (!self.loggedIn) {
        [self setUpLogInView];
    } else {
        [self setUpLogOutview];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)ifLoggedIn:(NSNumber *)ifLoggedIn
{
    _loggedIn = [ifLoggedIn boolValue];
}

- (void)setUpLogInView
{
    [self.dismissModalButton setHidden:YES];
    [self.mainInstruction setText: NSLocalizedString(@"Sign in with Facebook", @"Instruction to sign in with Facebook")];
    [self.subInstruction setText:NSLocalizedString(@"We don't post on behalf of you", @"Wording to assure the user that we do not post without their explicit permission")];
    [self.logInOrOutButton setBackgroundImage:[UIImage imageNamed:@"FacebookLogin"] forState:UIControlStateNormal];
    [self.logInOrOutButton setTitle:@"" forState:UIControlStateNormal];
    [self.logoutButtonLayer removeFromSuperlayer];
    [self.profilePic setHidden:YES];
}

- (void)setUpLogOutview
{
    [self.mainInstruction setText:@""];
    [self.subInstruction setText:@""];
    [self.dismissModalButton setHidden:NO];
    [self.logInOrOutButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.logInOrOutButton.layer addSublayer:[self createSignOutButton]];
    [self.logInOrOutButton setTitle:@"SIGN OUT" forState:UIControlStateNormal];
    [self.profilePic setHidden:NO];
    [self setupProfilePicMask];
    FBRequest *request = [FBRequest requestForMe];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            NSError *photoLoadingError = nil;
            NSString *facebookID = userData[@"id"];
            NSString *name = userData[@"name"];
            NSString *email = userData[@"email"];
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            [self.profilePic setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL options:NSDataReadingUncached error:&photoLoadingError]]];
            [self.mainInstruction setText:name];
            [self.subInstruction setText:email];
        }
    }];
    
}

- (void)setupProfilePicMask
{
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.profilePic.bounds];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = circle.CGPath;
    shapeLayer.frame = self.profilePic.bounds;
    self.profilePic.layer.mask = shapeLayer;
}

- (CAShapeLayer *)createSignOutButton
{
    CGRect buttonBounds = self.logInOrOutButton.bounds;
    
    UIBezierPath *buttonBox = [UIBezierPath bezierPathWithRoundedRect:buttonBounds cornerRadius:5.f];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor   = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = [UIColor darkGrayColor].CGColor;
    shapeLayer.lineWidth   = 1.f;
    shapeLayer.frame = buttonBounds;
    shapeLayer.path = buttonBox.CGPath;
    self.logoutButtonLayer = shapeLayer;
    
    return shapeLayer;
}

#pragma mark - Storyboard Actions
- (IBAction)dismissModal:(UIButton *)sender
{
    [self dismissModalView];
}

- (void)dismissModalView
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Login modal is being dismissed\n");
    }];
}

- (IBAction)loginOrLogout:(UIButton *)sender
{
    if (!self.loggedIn) {
        // The permissions requested from the user
        NSArray *permissionsArray = @[@"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
        
        // Login PFUser using Facebook
        [self.logInOrOutButton setHidden:YES];
        [self.loadingFBLogin startAnimating];
        [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
            [self.logInOrOutButton setHidden:NO];
            [self.loadingFBLogin stopAnimating];
            if (!user) {
                if (!error) {
                    NSLog(@"Uh oh. The user cancelled the Facebook login.");
                } else {
                    NSLog(@"Uh oh. An error occurred: %@", error);
                }
            } else if (user.isNew) {
                NSLog(@"User with facebook signed up and logged in!");
                self.loggedIn = YES;
                [self dismissModalView];
            } else {
                NSLog(@"User with facebook logged in!");
                self.loggedIn = YES;
                [self dismissModalView];
            }
        }];
    } else {
        [PFUser logOut]; // Log out
        // Return to login page
        self.loggedIn = NO;
        [self setUpLogInView];
    }
}

@end
