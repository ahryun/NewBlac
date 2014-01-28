//
//  InitialViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/27/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "InitialViewController.h"
#import "SharedManagedDocument.h"

@interface InitialViewController ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

static NSString *_ManagedObjectContextChanged = @"managedObjectContext";
static NSString *_SegueIdentifier = @"Go To Rootview";

@implementation InitialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addObserver:self forKeyPath:_ManagedObjectContextChanged options:NSKeyValueObservingOptionNew context:NULL];
    [self useDemoDocument];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:_ManagedObjectContextChanged]) {
        if (self.managedObjectContext) {
            [self performSegueWithIdentifier:_SegueIdentifier sender:self];
        }
    }
}

- (void)useDemoDocument
{
    [[SharedManagedDocument sharedInstance] performWithDocument:^(UIManagedDocument *document){
        self.managedObjectContext = document.managedObjectContext;
    }];
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
