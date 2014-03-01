//
//  VideosCollectionViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideosCollectionViewController.h"
#import "FramesCollectionViewController.h"
#import "Video+LifeCycle.h"
#import "CollectionViewLayout.h"
#import "Photo+LifeCycle.h"
#import "MotionVideoPlayer.h"

@interface VideosCollectionViewController () <ScrollingCellDelegate>

@property (nonatomic, strong) Video *selectedVideo;
@property (nonatomic, strong) PiecesCollectionCell *deleteCandidateCell;

@end

@implementation VideosCollectionViewController

static const NSString *PlayerReadyContext;

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.entityNameOfInterest = @"Video";
    self.propertyNameOfInterest = @"dateCreated";
    self.cacheNameOfInterest = @"Videos Cache";
    
    self.showPhotos = NO; // This tells the core data controller to provide videos
    [self initializeFetchedResultsController];
    CollectionViewLayout *layout = [[CollectionViewLayout alloc] init];
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.delegate = self;
    
    // Navigation Bar Buttons configuration
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self centerACell];
}

- (IBAction)presentMenuModally:(UIBarButtonItem *)sender
{
    // Do something
}

- (IBAction)addVideo:(UIBarButtonItem *)sender
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
    NSLog(@"Unsegued back to gallery\n");
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView Delegate
- (void)selectItemAtIndexPath:(PiecesCollectionCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedVideo = video;
    [self performSegueWithIdentifier:@"View And Edit Video" sender:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.deleteCandidateCell) [self.deleteCandidateCell reset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self centerACell];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self centerACell];
}

#pragma mark - Configure Video
- (void)centerACell {
    for (NSInteger sectionNumber = 0; sectionNumber < [self.collectionView numberOfSections]; sectionNumber++) {
        if ([self.collectionView numberOfItemsInSection:sectionNumber] > 0) {
            NSIndexPath *pathForCenterCell = [self.collectionView indexPathForItemAtPoint:CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMidY(self.collectionView.bounds))];
            [self.collectionView scrollToItemAtIndexPath:pathForCenterCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            if ([self.collectionView indexPathForCell:self.centerCell] != pathForCenterCell) {
                // If after scrolling, the user ended up on the same video, resume the video
                if (self.centerCell) self.centerCell.maskView.alpha = 0.3;
                PiecesCollectionCell *cell = (PiecesCollectionCell *)[self.collectionView cellForItemAtIndexPath:pathForCenterCell];
                cell.maskView.alpha = 0.0;
                self.centerCell = cell;
            }
        } else {
            // Create a blank video
            NSLog(@"No video!");
        }
    }
}

#pragma mark - NSFetchedResultsController
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"I'm in cellForItemAtIndexPath %@\n", indexPath);
    PiecesCollectionCell *cell = (PiecesCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Playable Video" forIndexPath:indexPath];
    cell.delegate = self;
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [cell prepareScrollView];
    [cell displayVideo];
    Photo *photo = [video.photos lastObject];
    cell.imageView.image = [UIImage imageWithData:photo.croppedPhoto];
    
    NSLog(@"Cell width and height are %f x %f", cell.bounds.size.width, cell.bounds.size.height);
    
    return cell;
}

#pragma mark - ScrollingCellDelegate
- (void)scrollingCellDidBeginPulling:(PiecesCollectionCell *)cell
{
    if (!self.deleteCandidateCell) {
        self.deleteCandidateCell = cell;
    } else if (self.deleteCandidateCell != cell) {
        [self.deleteCandidateCell reset];
        self.deleteCandidateCell = cell;
    }
}

- (void)deleteButtonPressed:(PiecesCollectionCell *)cell
{
    NSLog(@"Doh! I was told to delete this video\n");
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedVideo = video;
    [Video removeVideo:self.selectedVideo inManagedContext:self.managedObjectContext];
    [self centerACell];
}



@end