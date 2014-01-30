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
@property (nonatomic, weak) DeleteView *deleteView;

@end

@implementation VideosCollectionViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeFetchedResultsController];
    VideosCollectionViewLayout *layout = [[VideosCollectionViewLayout alloc] init];
    self.collectionView.collectionViewLayout = layout;
    
    DeleteView *deleteView = [[DeleteView alloc] init];
    deleteView.hidden = YES;
    self.deleteView = deleteView;
    UITapGestureRecognizer *deleteTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteVideo:)];
    [self.deleteView addGestureRecognizer:deleteTapGesture];
    
    UILongPressGestureRecognizer *longPress= [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = .5; //seconds
    longPress.delegate = self;
    longPress.delaysTouchesBegan = YES;
    [self.collectionView addGestureRecognizer:longPress];
}

- (IBAction)addVideo:(UIButton *)sender {
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
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"Video url = %@\n", video.compFilePath);
    self.selectedVideo = video;
    [self performSegueWithIdentifier:@"View And Edit Video" sender:self];
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
    [cell displayVideo];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Kind is %@\n", kind);
    UICollectionReusableView *reusableview = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        CollectionViewButtonsView *buttonView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Add a Video" forIndexPath:indexPath];
        reusableview = buttonView;
    }
    
    return reusableview;
}

#pragma mark - Gesture Recognizers
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) return;
    CGPoint point = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        // get the cell at indexPath (the one you long pressed)
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        // Make the hidden deleteView fade in
        if ([cell isKindOfClass:[VideoCollectionCell class]]) {
            [self.deleteView setFrame:cell.frame];
            [self.view addSubview:self.deleteView];
            [self.view bringSubviewToFront:self.deleteView];
            self.deleteView.hidden = NO;
            [self fadeOutDeleteView];
        } else {
            NSLog(@"Non-cell view has been selected with long press\n");
        }
    }
}

- (void)deleteVideo:(UITapGestureRecognizer *)tapGesture
{
    // delete the video
    if (tapGesture.state != UIGestureRecognizerStateEnded) return;
    CGPoint point = [tapGesture locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        // get the cell at indexPath (the one you long pressed)
        Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [Video removeVideo:video inManagedContext:self.managedObjectContext];
    }
}

- (void)fadeOutDeleteView
{
    [UIView animateWithDuration:1 delay:3
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.deleteView setAlpha:0.0];
                     }
                     completion:^(BOOL finished){
                         self.deleteView.hidden = YES;
                     }];
}

@end