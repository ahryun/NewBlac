//
//  InitialViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/27/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "InitialViewController.h"
#import "SharedManagedDocument.h"
#import <CoreData/CoreData.h>
#import "ParseSyncer.h"

@interface InitialViewController ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

static NSString *_ManagedObjectContextChanged = @"managedObjectContext";
static NSString *_SegueIdentifier = @"Go To Rootview";

@implementation InitialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    self.managedObjectContext = context;
    [ParseSyncer updateVideos];
    [ParseSyncer removeVideos];
    
    [self performSegueWithIdentifier:_SegueIdentifier sender:self];
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:_SegueIdentifier]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [segue.destinationViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
        }
    }
}

@end
