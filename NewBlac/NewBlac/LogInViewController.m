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

@end

@implementation LogInViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prefersStatusBarHidden];

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
    [self.mainInstruction setText:@"Sign in with Facebook"];
    [self.subInstruction setText:@"We don't post on behalf of you"];
    [self.profilePic setHidden:YES];
}

- (void)setUpLogOutview
{
    [self.dismissModalButton setHidden:NO];
    [self.mainInstruction setText:[NSString stringWithFormat:@"%@", [PFUser currentUser].username]];
    [self.subInstruction setText:[NSString stringWithFormat:@"%@", [PFUser currentUser].email]];
    [self.profilePic setHidden:NO];
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

- (IBAction)login:(UIButton *)sender
{
    if (!self.loggedIn) {
        // The permissions requested from the user
        NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
        
        // Login PFUser using Facebook
        [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
            if (!user) {
                if (!error) {
                    NSLog(@"Uh oh. The user cancelled the Facebook login.");
                } else {
                    NSLog(@"Uh oh. An error occurred: %@", error);
                }
            } else if (user.isNew) {
                NSLog(@"User with facebook signed up and logged in!");
                /*
                // request user data from FB and store it
                */
                [self dismissModalView];
            } else {
                NSLog(@"User with facebook logged in!");
                /*
                 // request user data from FB and store it
                 */
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
