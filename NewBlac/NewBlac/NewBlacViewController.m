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

@property (weak, nonatomic) IBOutlet UIButton *addPhoto;

@end

@implementation NewBlacViewController


- (IBAction)unwindAddToVideoBuffer:(UIStoryboardSegue *)segue
{
    // Add the photo to the buffer
    
}

- (IBAction)unwindCancelPhoto:(UIStoryboardSegue *)segue
{
    // Add the photo to the buffer
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Ready Camera"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [segue.destinationViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.video];
        }
    }
}

- (void)useDemoDocument
{
    [[SharedManagedDocument sharedInstance] performWithDocument:^(UIManagedDocument *document){
        self.managedObjectContext = document.managedObjectContext;
        if (!self.video && self.managedObjectContext) {
            // Put the path as nil, if you would Video object to create a random movie file path in Videos folder
            self.video = [Video videoWithPath:nil inManagedObjectContext:self.managedObjectContext];
        }
        [self.addPhoto setEnabled:YES];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.video) NSLog(@"Video aspect ratio is %f", [self.video.screenRatio floatValue]);
    
    if (!self.managedObjectContext) [self useDemoDocument];
    
}

@end
