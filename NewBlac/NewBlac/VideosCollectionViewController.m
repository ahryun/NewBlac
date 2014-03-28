//
//  VideosCollectionViewController.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideosCollectionViewController.h"
#import "FramesCollectionViewController.h"
#import "LogInViewController.h"
#import "Video+LifeCycle.h"
#import "CollectionViewLayout.h"
#import "Photo+LifeCycle.h"
#import "MotionVideoPlayer.h"
#import "ShareSocialViewController.h"
#import "VideoCreator.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Parse/Parse.h>
#import "TextEditingView.h"

@interface VideosCollectionViewController () <ScrollingCellDelegate, UIAlertViewDelegate, TextEditingViewDelegate>

@property (nonatomic, strong) NSNumber *ifAddNewVideo;
@property (nonatomic, strong) NSNumber *ifLoggedIn;
@property (nonatomic, strong) Video *selectedVideo;
@property (nonatomic, strong) Video *shareVideo;
@property (nonatomic, strong) VideoCreator *videoCreator;
@property (nonatomic, strong) PiecesCollectionCell *deleteCandidateCell;
@property (nonatomic, strong) UIView *snapshotView;
@property (nonatomic, strong) UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *noVideoScreen;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleButton;

@end

@implementation VideosCollectionViewController

static const NSString *videoCompilingDone;
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
    
    // When the view loads (not every time it appears)
    [self.managedObjectContext performBlock:^{
        [Video removeVideosInManagedContext:self.managedObjectContext];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Lighten the first cell
    [self centerACell];
    
    // If the user if logged in, then go ahead and use the app. If not, redirect to login view.
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        self.ifLoggedIn = [NSNumber numberWithBool:YES];
    } else {
        self.ifLoggedIn = [NSNumber numberWithBool:NO];
        [self showLoginView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    int videoCount = (int)[self.collectionView numberOfItemsInSection:0];
    [self resetToolbarWithPhotoCount:videoCount];
    [self.noVideoScreen setHidden:YES];
    if (videoCount == 0) {
        [self.noVideoScreen setHidden:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.ifAddNewVideo = [NSNumber numberWithBool:NO];
}

- (void)chooseCenterCell
{
    NSIndexPath *centerCellPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMidY(self.collectionView.bounds))];
    NSLog(@"My collectionview looks like %@", self.collectionView.indexPathsForVisibleItems);
    self.centerCell = (PiecesCollectionCell *)[self.collectionView cellForItemAtIndexPath:centerCellPath];
}

#pragma mark - Storyboard Actions

- (IBAction)presentMenuModally:(UIBarButtonItem *)sender
{
    // Do something
    [self showLoginView];
}

- (void)showLoginView
{
    [self performSegueWithIdentifier:@"Show Login View" sender:self];
}

- (IBAction)presentShareModally:(UIBarButtonItem *)sender
{
    NSIndexPath *pathForCenterCell = [self.collectionView indexPathForCell:self.centerCell];
    Video *video = [self.fetchedResultsController objectAtIndexPath:pathForCenterCell];
    self.shareVideo = video;
    [self compileVideo:video];
}

- (void)compileVideo:(Video *)videoToCompile
{
    NSLog(@"I am in compileVideo\n");
    [self.shareButton setImage:nil];
    [self.shareButton setTitle:NSLocalizedString(@"Compiling...", @"Telling the user that the frames are being processed to create a video")];
    CGSize size = CGSizeMake(self.navigationController.view.bounds.size.width, self.navigationController.view.bounds.size.height);
    dispatch_async(dispatch_get_main_queue(), ^(){
        if (!self.videoCreator) self.videoCreator = [[VideoCreator alloc] initWithVideo:videoToCompile withScreenSize:size];
        [self.videoCreator addObserver:self forKeyPath:@"videoDoneCreating" options:0 context:&videoCompilingDone];
        [self.videoCreator writeImagesToVideo];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &videoCompilingDone) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"Video compilating is %i", self.videoCreator.videoDoneCreating);
            if (self.videoCreator.videoDoneCreating) {
                // Change the videoModified date - to let Parse know to update the data when convenient
                [self.managedObjectContext performBlock:^{
                    [self.shareVideo setDateModified:[NSDate date]];
                }];
                
                // Bring up the share view
                [self performSegueWithIdentifier:@"Show Share Modal" sender:self];
                [self.videoCreator removeObserver:self forKeyPath:@"videoDoneCreating" context:&videoCompilingDone];
            }
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (IBAction)addVideo:(UIBarButtonItem *)sender
{
    NSLog(@"I'm in addVideo\n");
    self.selectedVideo = [Video videoWithPath:nil inManagedObjectContext:self.managedObjectContext];
    // Do manual segue "View And Edit Video"
    self.ifAddNewVideo = [NSNumber numberWithBool:YES];
    [self performSegueWithIdentifier:@"View And Edit Video" sender:self];
}

- (IBAction)editTitle:(UIBarButtonItem *)sender
{
    [self prepareTitleEditingView];
    [self showTextEditingView];
}

- (void)prepareTitleEditingView
{
    UIView *snapShot = [self.navigationController.view resizableSnapshotViewFromRect:self.navigationController.view.frame afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    snapShot.frame = self.navigationController.view.frame;
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:self.centerCell];
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    Photo *photo = [video.photos lastObject];
    TextEditingView *textEditingView = [[TextEditingView alloc] initWithFrame:CGRectOffset(snapShot.frame, 0, snapShot.frame.size.height)];
    [textEditingView setExistingTitle:video.title];
    [textEditingView setVideoImage:[UIImage imageWithData:photo.croppedPhoto]];
    textEditingView.delegate = self;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectUnion(snapShot.frame, textEditingView.frame)];
    [containerView setBackgroundColor:[UIColor whiteColor]];
    [containerView setOpaque:YES];
    [containerView addSubview:snapShot];
    [containerView addSubview:textEditingView];
    [self.navigationController.view addSubview:containerView];
    self.containerView = containerView;
}

- (void)showTextEditingView
{
    [UIView animateWithDuration:0.5 animations:^{
        [self.containerView setFrame:CGRectOffset(self.containerView.frame, 0, -self.containerView.frame.size.height / 2)];
    }];
}

#pragma mark - TextEditingView Delegate
- (void)dismissTextEditingViewDelegate:(TextEditingView *)view
{
    [UIView animateWithDuration:0.5 animations:^{
        [self.containerView setFrame:CGRectMake(0, 0, self.containerView.frame.size.width, self.containerView.frame.size.height)];
    } completion:^(BOOL finished) {
        [self.containerView removeFromSuperview];
        [self centerACell];
    }];
}

- (void)saveTitle:(NSString *)newTitle
{
    [self.managedObjectContext performBlock:^{
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:self.centerCell];
        Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (![newTitle isEqualToString:video.title] && [newTitle length]) {
            [video setTitle:newTitle];
        }
    }];
}

#pragma mark - ShareViewModal Delegate
- (void)dismissShareModalViewDelegate:(ShareSocialViewController *)view
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self centerACell];
    }];
}

#pragma mark - Update UIs
- (void)resetToolbarWithPhotoCount:(NSUInteger)videoCount
{
    if (videoCount > 0) {
        if (self.navigationController.toolbarHidden) {
            [self.navigationController setToolbarHidden:NO animated:NO];
        }
    } else {
        if (!self.navigationController.toolbarHidden) {
            [self.navigationController setToolbarHidden:YES animated:YES];
        }
    }
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Preparing for segue\n");
    if ([segue.identifier isEqualToString:@"View And Edit Video"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.selectedVideo];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(ifAutoCameraMode:)]) {
            [segue.destinationViewController performSelector:@selector(ifAutoCameraMode:) withObject:self.ifAddNewVideo];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [segue.destinationViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
        }
    }
    if ([segue.identifier isEqualToString:@"Show Login View"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(ifLoggedIn:)]) {
            [segue.destinationViewController performSelector:@selector(ifLoggedIn:) withObject:self.ifLoggedIn];
        }
    }
    if ([segue.identifier isEqualToString:@"Show Share Modal"]) {
        UIView *snapShotView = [self.navigationController.view resizableSnapshotViewFromRect:self.navigationController.view.frame afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
        if ([segue.destinationViewController respondsToSelector:@selector(setSnapShotView:)]) {
            [segue.destinationViewController performSelector:@selector(setSnapShotView:) withObject:snapShotView];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.shareVideo];
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
            [self chooseCenterCell];
            NSIndexPath *pathForCenterCell = [self.collectionView indexPathForCell:self.centerCell];
            [self.collectionView scrollToItemAtIndexPath:pathForCenterCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            if (self.centerCell) self.centerCell.maskView.alpha = 0.3;
            self.centerCell.maskView.alpha = 0.0;
            Video *video = [self.fetchedResultsController objectAtIndexPath:pathForCenterCell];
            if ([video.title length]) {
                NSRange stringRange = {0, MIN([video.title length], SHORT_TEXT_LENGTH)};
                stringRange = [video.title rangeOfComposedCharacterSequencesForRange:stringRange];
                NSString *shortString = [video.title substringWithRange:stringRange];
                if ([video.title length] > SHORT_TEXT_LENGTH) {
                    shortString = [shortString stringByAppendingString:@"..."];
                }
                [self.titleButton setTitle:shortString];
                self.titleButton.image = nil;
            } else {
                [self.titleButton setTitle:nil];
                self.titleButton.image = [UIImage imageNamed:@"MoreButton"];
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
    NSString *deleteString = NSLocalizedString(@"delete", @"Action button to delete a piece of data");
    NSString *cancelString = NSLocalizedString(@"cancel", @"Action button to cancel action or modal");
    UIAlertView *deleteConfirmButton = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete this piece?", @"Ask the user if she wants to delete this video") message:@"" delegate:self cancelButtonTitle:[cancelString capitalizedString] otherButtonTitles:[[NSString stringWithFormat:@"%@", deleteString] capitalizedString], nil];
    [deleteConfirmButton show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex]) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self.deleteCandidateCell reset];
    } else {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:self.deleteCandidateCell];
        Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
        self.selectedVideo = video;
        [Video removeVideo:self.selectedVideo inManagedContext:self.managedObjectContext];
        [self centerACell];
        
        int videoCount = (int)[self.collectionView numberOfItemsInSection:0];
        [self resetToolbarWithPhotoCount:videoCount];
        if (videoCount == 0) {
            [self.noVideoScreen setHidden:NO];
        }
    }
}

@end