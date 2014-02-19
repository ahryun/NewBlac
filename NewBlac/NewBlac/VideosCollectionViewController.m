//
//  VideosCollectionViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideosCollectionViewController.h"
#import "NewBlacViewController.h"
#import "VideoCollectionCell.h"
#import "Video+LifeCycle.h"
#import "CollectionViewButtonsView.h"
#import "VideosCollectionViewLayout.h"
#import <MediaPlayer/MediaPlayer.h>
#import "DeleteView.h"

@interface VideosCollectionViewController ()

@property (nonatomic, strong) Video *selectedVideo;
@property (weak, nonatomic) IBOutlet DeleteView *deleteView;
@property (nonatomic) BOOL shouldDelete;

@end

@implementation VideosCollectionViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeFetchedResultsController];
    VideosCollectionViewLayout *layout = [[VideosCollectionViewLayout alloc] init];
    self.shouldDelete = NO;
    self.collectionView.collectionViewLayout = layout;
    
    // Navigation Bar Buttons configuration
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MenuButton"] style:UIBarButtonItemStylePlain target:self action:@selector(presentMenuModally)];
    UIBarButtonItem *addVideoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddVideoButton"] style:UIBarButtonItemStylePlain target:self action:@selector(addVideo)];
    self.navigationItem.leftBarButtonItem = menuButton;
    self.navigationItem.rightBarButtonItem = addVideoButton;
}

- (void)presentMenuModally
{
    // Do something
}

- (void)addVideo
{
    NSLog(@"I'm in addVideo\n");
    self.selectedVideo = [Video videoWithPath:nil inManagedObjectContext:self.managedObjectContext];
    // Do manual segue "View And Edit Video"
    [self performSegueWithIdentifier:@"View And Edit Video" sender:self];
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Preparing for segue\n");
    if ([segue.identifier isEqualToString:@"View And Edit Video"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.selectedVideo];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [segue.destinationViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
        }
    }
}

#pragma mark - Unwind Segues
- (IBAction)unwindAddToVideos:(UIStoryboardSegue *)segue
{
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // if the x button is shown, delete the video. Otherwise do the segue.
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedVideo = video;
    if (self.shouldDelete) {
        // Popup with do you want to delete? needs to pop up.
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete" message:@"Do you want to delete this video?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
        [alertView show];
    } else {
        self.selectedVideo = video;
        [self performSegueWithIdentifier:@"View And Edit Video" sender:self];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    } else if (buttonIndex == 1) {
        [Video removeVideo:self.selectedVideo inManagedContext:self.managedObjectContext];
    }
}

#pragma mark - NSFetchedResultsController
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"I'm in cellForItemAtIndexPath\n");
    VideoCollectionCell *cell = (VideoCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Playable Video" forIndexPath:indexPath];
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSURL *videoURL = [NSURL fileURLWithPath:video.compFilePath];
    NSLog(@"Video URL is %@\n", videoURL.description);
    [cell setVideoURL:videoURL];
    [cell.layer setCornerRadius:10.0f];
    [cell displayVideo];
    return cell;
}

#pragma mark - Gesture Recognizers
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) return;
    CGPoint point = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        // get the cell at indexPath (the one you long pressed)
        VideoCollectionCell *cell = (VideoCollectionCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [UIImageView animateWithDuration:1 animations:^{
                                  cell.imageView.alpha = 1.0;
                              } completion:^(BOOL finished) {
                                  NSLog(@"X button appeared\n");
                                  self.shouldDelete = YES;
                                  [self fadeOutDeleteView:cell.imageView];
                              }];
    }
}

- (void)fadeOutDeleteView:(UIImageView *)imageView
{
    NSLog(@"I'm in fadeOutDeleteView\n");
    [UIImageView animateWithDuration:1 delay:3
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         imageView.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         self.shouldDelete = NO;
                         NSLog(@"X button disappeared\n");
                     }];
}

@end