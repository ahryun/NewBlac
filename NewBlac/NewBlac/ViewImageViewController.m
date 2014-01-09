//
//  ViewImageViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/2/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "ViewImageViewController.h"

@interface ViewImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *croppedImageView;

- (IBAction)editImage:(UIGestureRecognizer *)gestureRecognizer;

@end

@implementation ViewImageViewController

- (void)setPhoto:(Photo *)photo
{
    // Need to change to Core Data
    _photo = photo;
}

- (void)displayPhoto
{
    // Need to get the core data photo and get the photo path and convert the photo in file system to UIImage
    if (self.photo) {
        NSData *photoData = [NSData dataWithContentsOfFile:self.photo.croppedPhotoFilePath];
        self.croppedImageView.image = [UIImage imageWithData:photoData];
        self.croppedImageView.frame = CGRectMake(0, 0,
                                                 self.croppedImageView.image.size.width,
                                                 self.croppedImageView.image.size.height);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self displayPhoto];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindDoneEditingImage:(UIStoryboardSegue *)segue
{
    // Nothing necessary to be done here
}

- (IBAction)editImage:(UIGestureRecognizer *)gestureRecognizer
{
    // manual segue to the next page where user can edit the location of corners
    NSLog(@"I wanna edit the image\n");
    [self performSegueWithIdentifier:@"Edit Image" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Edit Image"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setPhoto:)]) {
            [segue.destinationViewController performSelector:@selector(setPhoto:) withObject:self.photo];
        }
    }
}


@end
