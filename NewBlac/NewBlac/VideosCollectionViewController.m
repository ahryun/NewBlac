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
#import "ParseSyncer.h"

@interface VideosCollectionViewController () <ScrollingCellDelegate, UIAlertViewDelegate, TextEditingViewDelegate>

@property (nonatomic, strong) NSNumber *ifAddNewVideo;
@property (nonatomic, strong) NSNumber *ifLoggedIn;
@property (nonatomic, strong) Video *selectedVideo;
@property (nonatomic, strong) Video *shareVideo;
@property (nonatomic, strong) VideoCreator *videoCreator;
@property (nonatomic, strong) PiecesCollectionCell *deleteCandidateCell;
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
    
    self.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    
    [self setUpFetchedResultController];
    [self syncParse];
    [self initializeFetchedResultsController];
    [self setUpCollectionView];
    
    // When the view loads (not every time it appears)
    [Video removeVideos];
}

- (void)setUpFetchedResultController
{
    self.entityNameOfInterest = @"Video";
    self.propertyNameOfInterest = @"dateCreated";
    self.cacheNameOfInterest = @"Videos Cache";
    self.showPhotos = NO;  // This tells the core data controller to provide videos
}

- (void)syncParse
{
    [ParseSyncer updateVideos];
    [ParseSyncer removeVideos];
}

- (void)setUpCollectionView
{
    CollectionViewLayout *layout = [[CollectionViewLayout alloc] init];
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUInteger videoCount = [self.collectionView numberOfItemsInSection:0];
    [self resetToolbarWithPhotoCount:videoCount];
    [self showNoVideoScreen:videoCount];
}

- (void)showNoVideoScreen:(NSUInteger)videoCount
{
    if (videoCount == 0) {
        [self.noVideoScreen setHidden:NO];
    } else {
        [self.noVideoScreen setHidden:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Lighten the first cell
    [self centerACell];
    [self askUserToLogin];
}

- (void)askUserToLogin
{
    // If the user if logged in, then go ahead and use the app. If not, redirect to login view.
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        self.ifLoggedIn = [NSNumber numberWithBool:YES];
    } else {
        self.ifLoggedIn = [NSNumber numberWithBool:NO];
        [self showLoginView];
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
    [self chooseCenterCell];
    [self changeShareButtonTitle];
    self.shareVideo = [self determineVideo:self.centerCell];
    [self compileVideo:self.shareVideo];
}

- (Video *)determineVideo:(PiecesCollectionCell *)centerCell
{
    Video *video = nil;
    if (centerCell) {
        NSIndexPath *pathForCenterCell = [self.collectionView indexPathForCell:centerCell];
        video = [self.fetchedResultsController objectAtIndexPath:pathForCenterCell];
    } else {
        NSLog(@"Center cell not chosen\n");
    }
    return video;
}

- (void)compileVideo:(Video *)videoToCompile
{
    NSLog(@"I am in compileVideo\n");
	__weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(){
        typeof(self) strongSelf = weakSelf;
        CGSize size = CGSizeMake(strongSelf.navigationController.view.bounds.size.width, strongSelf.navigationController.view.bounds.size.height);
        if (!strongSelf.videoCreator) strongSelf.videoCreator = [[VideoCreator alloc] initWithVideo:videoToCompile withScreenSize:size];
        [strongSelf.videoCreator addObserver:strongSelf forKeyPath:@"videoDoneCreating" options:0 context:&videoCompilingDone];
        [strongSelf.videoCreator writeImagesToVideo];
    });
}

- (void)changeShareButtonTitle
{
    [self.shareButton setImage:nil];
    [self.shareButton setTitle:NSLocalizedString(@"Compiling...", @"Telling the user that the frames are being processed to create a video")];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &videoCompilingDone) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^(){
            typeof(self) strongSelf = weakSelf;
            NSLog(@"Video compilating is %i", strongSelf.videoCreator.videoDoneCreating);
            if (strongSelf.videoCreator.videoDoneCreating) {
                // Change the videoModified date - to let Parse know to update the data when convenient
                [strongSelf.shareVideo setDateModified:[NSDate date]];
                
                // Bring up the share view
                [strongSelf.videoCreator removeObserver:strongSelf forKeyPath:@"videoDoneCreating" context:&videoCompilingDone];
                [strongSelf performSegueWithIdentifier:@"Show Share Modal" sender:strongSelf];
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
    // Create a brand new video object in Core Data
    self.selectedVideo = [Video videoWithPath:nil];
    // Do manual segue "View And Edit Video"
    self.ifAddNewVideo = [NSNumber numberWithBool:YES];
    [self performSegueWithIdentifier:@"View And Edit Video" sender:self];
}

- (IBAction)editTitle:(UIBarButtonItem *)sender
{
    [self chooseCenterCell];
    [self prepareTitleEditingView];
    [self showTextEditingView];
}

- (void)prepareTitleEditingView
{
    UIView *snapShot = [self createSnapshotView];
    
    [self chooseCenterCell];
    Video *video = [self determineVideo:self.centerCell];
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

- (UIView *)createSnapshotView
{
    UIView *snapShot = [self.navigationController.view resizableSnapshotViewFromRect:self.navigationController.view.frame afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    snapShot.frame = self.navigationController.view.frame;
    return snapShot;
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
    __weak typeof(self) weakSelf = self;
    [self.managedObjectContext performBlock:^{
        typeof(self) strongSelf = weakSelf;
        [self chooseCenterCell];
        Video *video = [strongSelf determineVideo:strongSelf.centerCell];
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
    }
    if ([segue.identifier isEqualToString:@"Show Login View"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(ifLoggedIn:)]) {
            [segue.destinationViewController performSelector:@selector(ifLoggedIn:) withObject:self.ifLoggedIn];
        }
    }
    if ([segue.identifier isEqualToString:@"Show Share Modal"]) {
        UIView *snapShot = [self createSnapshotView];
        if ([segue.destinationViewController respondsToSelector:@selector(setSnapShotView:)]) {
            [segue.destinationViewController performSelector:@selector(setSnapShotView:) withObject:snapShot];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.shareVideo];
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
            Video *video = [self determineVideo:self.centerCell];
            [self setVideoTitleWith:video];
        } else {
            // Create a blank video
            NSLog(@"No video!");
        }
    }
}

- (void)setVideoTitleWith:(Video *)video {
    if (video && [video.title length]) {
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
        [Video removeVideo:self.selectedVideo];
        [self centerACell];
        
        NSUInteger videoCount = [self.collectionView numberOfItemsInSection:0];
        [self resetToolbarWithPhotoCount:videoCount];
        [self showNoVideoScreen:videoCount];
    }
}

@end