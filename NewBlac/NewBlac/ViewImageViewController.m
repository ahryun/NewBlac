//
//  ViewImageViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/2/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "ViewImageViewController.h"

@interface ViewImageViewController ()

@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (weak, nonatomic) UIImageView *croppedImageView;

- (IBAction)editImage:(UIGestureRecognizer *)gestureRecognizer;

@end

@implementation ViewImageViewController

- (void)setPhoto:(Photo *)photo
{
    _photo = photo;
}

- (void)setCanvas:(Canvas *)canvas
{
    _canvas = canvas;
}

- (void)displayPhoto
{
    // Need to get the core data photo and get the photo path and convert the photo in file system to UIImage
    if (self.photo) {
        
        NSData *photoData = [NSData dataWithContentsOfFile:self.photo.croppedPhotoFilePath];
        
        UIImage *image = [UIImage imageWithData:photoData];
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
        self.croppedImageView = imageView;
        
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.buttonView.opaque = NO;
    self.buttonView.backgroundColor = [UIColor clearColor];
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
        if ([segue.destinationViewController respondsToSelector:@selector(setCanvas:)]) {
            [segue.destinationViewController performSelector:@selector(setCanvas:) withObject:self.canvas];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.croppedImageView = nil;
}

@end
