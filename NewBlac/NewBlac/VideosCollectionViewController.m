//
//  VideosCollectionViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideosCollectionViewController.h"
#import "NewBlacViewController.h"
#import "Video+LifeCycle.h"
#import "VideosCollectionViewLayout.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Photo+LifeCycle.h"
#import "MotionVideoPlayer.h"

@interface VideosCollectionViewController () <ScrollingCellDelegate>

@property (nonatomic, strong) Video *selectedVideo;
@property (nonatomic, strong) VideoCollectionCell *deleteCandidateCell;
@property (nonatomic, strong) MotionVideoPlayer *videoPlayerObj;

@end

@implementation VideosCollectionViewController

static const NSString *PlayerReadyContext;

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeFetchedResultsController];
    VideosCollectionViewLayout *layout = [[VideosCollectionViewLayout alloc] init];
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.delegate = self;
    
    // Navigation Bar Buttons configuration
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MenuButton"] style:UIBarButtonItemStylePlain target:self action:@selector(presentMenuModally)];
    UIBarButtonItem *addVideoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddVideoButton"] style:UIBarButtonItemStylePlain target:self action:@selector(addVideo)];
    self.navigationItem.leftBarButtonItem = menuButton;
    self.navigationItem.rightBarButtonItem = addVideoButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self centerACell];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.videoPlayerObj removeObserver:self forKeyPath:@"playerIsReady" context:&PlayerReadyContext];
    [self.videoPlayerObj unregisterNotification];
    self.videoPlayerObj.isCancelled = YES;
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
- (void)selectItemAtIndexPath:(VideoCollectionCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedVideo = video;
    [self performSegueWithIdentifier:@"View And Edit Video" sender:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.deleteCandidateCell) [self.deleteCandidateCell reset];
    if (self.videoPlayerObj) [self.videoPlayerObj pauseVideo];
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
            if ([self.collectionView indexPathForCell:self.centerCell] == pathForCenterCell) {
                // If after scrolling, the user ended up on the same video, resume the video
                [self.videoPlayerObj playVideo];
            } else {
                if (self.centerCell) {
                    // Old center cell
                    self.centerCell.maskView.alpha = 0.3;
                    [self resetVideo];
                }
                // New center cell
                VideoCollectionCell *cell = (VideoCollectionCell *)[self.collectionView cellForItemAtIndexPath:pathForCenterCell];
                cell.maskView.alpha = 0.0;
                self.centerCell = cell;
                [self.videoPlayerObj replacePlayerItem:self.centerCell.videoURL];
                [self loadAssetFromVideo];
            }
        } else {
            // Create a blank video
            NSLog(@"No video!");
        }
    }
}

- (void)loadAssetFromVideo
{
    if (!self.videoPlayerObj) self.videoPlayerObj = [[MotionVideoPlayer alloc] init];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.centerCell.videoURL path]]) {
        [self.videoPlayerObj loadAssetFromVideo:self.centerCell.videoURL];
        [self.videoPlayerObj addObserver:self forKeyPath:@"playerIsReady" options:0 context:&PlayerReadyContext];
    } else {
        // Video data object exists but no video saved yet
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &PlayerReadyContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setPlayerInLayer:self.videoPlayerObj.player];
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (void)setPlayerInLayer:(AVPlayer *)player
{
    if ((self.videoPlayerObj.playerIsReady) &&
        ([self.videoPlayerObj.playerItem status] == AVPlayerItemStatusReadyToPlay)) {
        NSLog(@"Setting the video layer\n");
        [self.centerCell prepareVideoLayer:player];
        [self.videoPlayerObj playVideo];
    } else {
        NSLog(@"Video not ready to play\n");
    }
}

- (void)resetVideo
{
    // Reset video to photo
    [self.centerCell removeVideoLayer];
}

#pragma mark - NSFetchedResultsController
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"I'm in cellForItemAtIndexPath %@\n", indexPath);
    VideoCollectionCell *cell = (VideoCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Playable Video" forIndexPath:indexPath];
    cell.delegate = self;
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSURL *videoURL = [NSURL fileURLWithPath:video.compFilePath];
    NSLog(@"Video URL is %@\n", videoURL.description);
    [cell setVideoURL:videoURL];
    [cell prepareScrollView];
    [cell displayVideo];
    Photo *photo = [video.photos lastObject];
    cell.imageView.image = [UIImage imageWithData:photo.croppedPhoto];
    
    NSLog(@"Cell width and height are %f x %f", cell.bounds.size.width, cell.bounds.size.height);
    
    return cell;
}

#pragma mark - ScrollingCellDelegate
- (void)scrollingCellDidBeginPulling:(VideoCollectionCell *)cell
{
    if (!self.deleteCandidateCell) {
        self.deleteCandidateCell = cell;
    } else if (self.deleteCandidateCell != cell) {
        [self.deleteCandidateCell reset];
        self.deleteCandidateCell = cell;
    }
    
    // Pause the video if the user tries to delete any video while it's playing
    [self.videoPlayerObj pauseVideo];
}

- (void)deleteButtonPressed:(VideoCollectionCell *)cell
{
    NSLog(@"Doh! I was told to delete this video\n");
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedVideo = video;
    [Video removeVideo:self.selectedVideo inManagedContext:self.managedObjectContext];
    [self centerACell];
}



@end