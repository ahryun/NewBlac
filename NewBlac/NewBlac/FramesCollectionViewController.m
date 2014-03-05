//
//  blacViewController.m
//  Blac
//
//  Created by Ahryun Moon on 11/20/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "FramesCollectionViewController.h"
#import "VideoCreator.h"
//#import "VideoPlayView.h"
//#import "MotionVideoPlayer.h"
#import "Photo+LifeCycle.h"
#import "CollectionViewLayout.h"
#import "EditImageViewController.h"
#import "FullScreenMovieViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface FramesCollectionViewController () <UIPickerViewDataSource, UIPickerViewDelegate, ScrollingCellDelegate>

@property (nonatomic) BOOL needToCompile;
@property (strong, nonatomic) VideoCreator *videoCreator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *framesPerSecond;
@property (strong, nonatomic) UIPickerView *pickerView;
@property (strong, nonatomic) UIView *snapshotView;
@property (nonatomic, strong) PiecesCollectionCell *deleteCandidateCell;
@property (nonatomic, strong) Photo *selectedPhoto;
@property (nonatomic) Canvas *canvas;

@end

@implementation FramesCollectionViewController

static const NSString *videoCompilingDone;

- (void)setVideo:(Video *)video
{
    _video = video;
}

- (NSManagedObject *)specificModel
{
    return self.video;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.entityNameOfInterest = @"Photo";
    self.propertyNameOfInterest = @"indexInVideo";
    self.cacheNameOfInterest = @"Frames Cache";

    self.showPhotos = YES; // This tells the core data controller to provide photos
    self.needToCompile = NO;
    UIImage *playButtonImg = [[UIImage imageNamed:@"PlayButton"]
                              imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.playButton.image = playButtonImg;
    [self.framesPerSecond setTitle:[NSString stringWithFormat:@"%ld FPS", (long)[self.video.framesPerSecond integerValue]]];
    
    [self initializeFetchedResultsController];
    CollectionViewLayout *layout = [[CollectionViewLayout alloc] init];
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.delegate = self;
    
    // Navigation Bar Buttons configuration
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIImage *playButtonImg;
    if ([self.video.photos count] > 1) {
        playButtonImg = [[UIImage imageNamed:@"PlayButton"]
                         imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.playButton.enabled = YES;
    } else {
        playButtonImg = [[UIImage imageNamed:@"PlayButton"]
                         imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.playButton.enabled = NO;
    }
    self.playButton.image = playButtonImg;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self centerACell];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // Hackish way to know if the user clicked "Back" button in the navigation controller
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) [self cleanUpBeforeReturningToGallery];
}

- (void)cleanUpBeforeReturningToGallery
{
    NSLog(@"I'm in clean up\n");
    if ([self.video.photos count] < 1) {
        [Video removeVideo:self.video inManagedContext:self.managedObjectContext];
    } else {
        // Save the video to child context, which pushes the changes to the parent context on main thread. This will eventually be saved to persistent store when the UIManagedDocument closes.
        NSError *error;
        [self.managedObjectContext save:&error];
    }
}

#pragma mark - Segues
- (IBAction)unwindAddToVideoBuffer:(UIStoryboardSegue *)segue
{
    // When the user takes a photo with the camera - photo added
    self.needToCompile = YES;
}

- (IBAction)unwindCancelPhoto:(UIStoryboardSegue *)segue
{
    // When the user cancels camera - no photo
    self.needToCompile = NO;
}

- (IBAction)unwindDoneEditingImage:(UIStoryboardSegue *)segue
{
    // When the user edited corners - photo added
    self.needToCompile = YES;
}

- (IBAction)unwindCancelEditingImage:(UIStoryboardSegue *)segue
{
    // When the user comes back from editing corner mode without making any change - no photo
    self.needToCompile = NO;
}

- (IBAction)doneWatchingVideo:(UIStoryboardSegue *)segue
{
    // When the user comes back from editing corner mode without making any change - no photo
    self.needToCompile = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"I'm in segue\n");
    if ([segue.identifier isEqualToString:@"Ready Camera"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.video];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [segue.destinationViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
        }
    }
    if ([segue.identifier isEqualToString:@"Edit Corners"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setPhoto:)]) {
            [segue.destinationViewController performSelector:@selector(setPhoto:) withObject:self.selectedPhoto];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setCanvas:)]) {
            [segue.destinationViewController performSelector:@selector(setCanvas:) withObject:self.canvas];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.video];
        }
    }
    if ([segue.identifier isEqualToString:@"Play Full Screen Video"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVideoPath:)]) {
            [segue.destinationViewController performSelector:@selector(setVideoPath:) withObject:self.video.compFilePath];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setFramesPerSecond:)]) {
            [segue.destinationViewController performSelector:@selector(setFramesPerSecond:) withObject:self.video.framesPerSecond];
        }
    }
}

#pragma mark - Model

- (void)compileVideo
{
    if (self.video && [self.video.photos count] > 0) {
        CGSize size = CGSizeMake(self.navigationController.view.bounds.size.width, self.navigationController.view.bounds.size.height);
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (!self.videoCreator) self.videoCreator = [[VideoCreator alloc] initWithVideo:self.video withScreenSize:size];
            [self.videoCreator addObserver:self forKeyPath:@"videoDoneCreating" options:0 context:&videoCompilingDone];
            [self.videoCreator writeImagesToVideo];
        });
    }
}

- (IBAction)play:sender {
    // Prepare full page video
    if (self.needToCompile) {
        [self compileVideo];
    } else {
        [self performSegueWithIdentifier:@"Play Full Screen Video" sender:self];
    }
    
#warning Let the user know that the video is compiling
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &videoCompilingDone) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"Video compilating is %hhd", self.videoCreator.videoDoneCreating);
            if (self.videoCreator.videoDoneCreating) {
                [self performSegueWithIdentifier:@"Play Full Screen Video" sender:self];
            }
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

#pragma mark - UIPickerView
- (IBAction)chooseFramesPerSecond:(UIBarButtonItem *)sender
{
    [self prepareFramesPerSecondPickerView];
    
    // Animation to bring it up
    [UIView animateWithDuration:1 animations:^{
        self.snapshotView.frame = CGRectOffset(self.snapshotView.frame, 0, -CGRectGetHeight(self.pickerView.frame));
        self.pickerView.frame = CGRectOffset(self.pickerView.frame, 0, -CGRectGetHeight(self.pickerView.frame));
    }];
}

- (void)prepareFramesPerSecondPickerView
{
    // Create snapshot
    UIView *snapShot = [self.navigationController.view resizableSnapshotViewFromRect:self.navigationController.view.frame afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    snapShot.frame = self.navigationController.view.frame;
    [self.navigationController.view addSubview:snapShot];
    self.snapshotView = snapShot;
    [self.snapshotView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removePickerView)]];
    
    // Create picker view
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    pickerView.showsSelectionIndicator = YES;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    pickerView.backgroundColor = [UIColor whiteColor];
    CGRect pickerViewFrame = CGRectMake(0, CGRectGetHeight(self.navigationController.view.frame),
                                        CGRectGetWidth(pickerView.frame),
                                        CGRectGetHeight(pickerView.frame));
    [pickerView setFrame:pickerViewFrame];
    [pickerView selectRow:[self.video.framesPerSecond integerValue]-1 inComponent:0 animated:NO];
    [self.navigationController.view addSubview:pickerView];
    self.pickerView = pickerView;
}

- (void)removePickerView
{
    // Animation to bring it up
    [UIView animateWithDuration:1 animations:^{
        self.snapshotView.frame = CGRectOffset(self.snapshotView.frame, 0, CGRectGetHeight(self.pickerView.frame));
        self.pickerView.frame = CGRectOffset(self.pickerView.frame, 0, CGRectGetHeight(self.pickerView.frame));
    } completion:^(BOOL finished) {
        [self.snapshotView removeFromSuperview];
        [self.pickerView removeFromSuperview];
    }];
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 3;
}

#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%d Frames Per Second", row + 1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // perform some action
    NSNumber *framesPerSecond = [NSNumber numberWithInteger:row + 1];
    [self.video setFramesPerSecond:framesPerSecond];
    [self.framesPerSecond setTitle:[NSString stringWithFormat:@"%ld FPS", (long)[framesPerSecond integerValue]]];
}

#pragma mark - UICollectionView Delegate
- (void)selectItemAtIndexPath:(PiecesCollectionCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedPhoto = photo;
    UIImage *originalPhoto = [UIImage imageWithData:self.selectedPhoto.originalPhoto];
    float focalLength = [self.selectedPhoto.focalLength floatValue];
    float apertureSize = [self.selectedPhoto.apertureSize floatValue];
    float aspectRatio = [self.video.screenRatio floatValue];
    Canvas *canvas = [[Canvas alloc] initWithPhoto:originalPhoto withFocalLength:focalLength withApertureSize:apertureSize withAspectRatio:aspectRatio];
    self.canvas = canvas;
    [self performSegueWithIdentifier:@"Edit Corners" sender:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.deleteCandidateCell) [self.deleteCandidateCell reset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) [self centerACell];
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
    PiecesCollectionCell *cell = (PiecesCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Video Frame" forIndexPath:indexPath];
    cell.delegate = self;
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [cell prepareScrollView];
    [cell displayVideo];
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
    UIAlertView *deleteConfirmButton = [[UIAlertView alloc] initWithTitle:@"Delete this frame?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [deleteConfirmButton show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex]) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self.deleteCandidateCell reset];
    } else {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:self.deleteCandidateCell];
        Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
        self.selectedPhoto = photo;
        [Photo deletePhoto:photo inContext:self.managedObjectContext];
        [self centerACell];
    }
}

@end
