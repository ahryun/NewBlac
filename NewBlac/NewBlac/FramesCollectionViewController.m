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

@interface FramesCollectionViewController () <UIPickerViewDataSource, UIPickerViewDelegate, ScrollingCellDelegate, EditImageViewControllerDelegate>

@property (nonatomic) BOOL needToCompile;
@property (nonatomic) BOOL autoCameraMode;
@property (strong, nonatomic) VideoCreator *videoCreator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *framesPerSecond;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *noOfFrames;
@property (weak, nonatomic) IBOutlet UIImageView *noFramesScreen;
@property (strong, nonatomic) UIPickerView *pickerView;
@property (strong, nonatomic) UIView *snapshotView;
@property (nonatomic, strong) PiecesCollectionCell *deleteCandidateCell;
@property (nonatomic, strong) NSIndexPath *selectedCellIndexPath;
@property (nonatomic, strong) Photo *selectedPhoto;
@property (nonatomic) Canvas *canvas;

@end

@implementation FramesCollectionViewController

static const NSString *videoCompilingDone;
static const NSArray *fpsArray;

- (void)setVideo:(Video *)video
{
    _video = video;
    [self setVideoTitle:video];
}

- (void)setVideoTitle:(Video *)video
{
    if ([video.title length]) {
        // Limit the title to be 10 characters
        NSRange stringRange = {0, MIN([video.title length], SHORT_TEXT_LENGTH)};
        stringRange = [video.title rangeOfComposedCharacterSequencesForRange:stringRange];
        NSString *shortString = [video.title substringWithRange:stringRange];
        if ([video.title length] > SHORT_TEXT_LENGTH) {
            shortString = [shortString stringByAppendingString:@"..."];
        }
        self.navigationItem.title = shortString;
    } else {
        self.navigationItem.title = NSLocalizedString(@"No Title", @"Display that the video doesn't have any title");
    }
}

- (void)ifAutoCameraMode:(NSNumber *)ifNewVideo
{
    self.autoCameraMode = [ifNewVideo boolValue];
}

- (NSManagedObject *)specificModel
{
    return self.video;
}

#pragma mark - View Lifecycle
- (void)setUpFetchedResultController
{
    self.entityNameOfInterest = @"Photo";
    self.propertyNameOfInterest = @"indexInVideo";
    self.cacheNameOfInterest = @"Frames Cache";
    self.showPhotos = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    
    [self setUpFetchedResultController]; // This tells the core data controller to provide photos
    self.needToCompile = NO;
    [self initializeFetchedResultsController];
    [self setUpCollectionView];
    [self setUpFPS];
}

- (void)setUpFPS
{
    [self.framesPerSecond setTitle:[NSString stringWithFormat:NSLocalizedString(@"%ld FPS", @"Frames per second"), (long)[self.video.framesPerSecond integerValue]]];
    fpsArray = @[@1, @3, @5];
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
    [self updateUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Lighten the first cell
    [self chooseCenterCell];
    [self centerACell];
    
    if (self.autoCameraMode) [self performSegueWithIdentifier:@"Ready Camera" sender:self];
}

- (void)chooseCenterCell
{
    NSIndexPath *centerCellPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMidY(self.collectionView.bounds))];
    NSLog(@"My collectionview looks like %@", self.collectionView.indexPathsForVisibleItems);
    self.centerCell = (PiecesCollectionCell *)[self.collectionView cellForItemAtIndexPath:centerCellPath];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (!self.videoCreator.videoDoneCreating) [self.videoCreator removeObserver:self forKeyPath:@"videoDoneCreating" context:&videoCompilingDone];
    self.autoCameraMode = NO;
}

#pragma mark - Segues
- (IBAction)unwindAddToVideoBuffer:(UIStoryboardSegue *)segue
{
    // When the user takes a photo with the camera - photo added
    self.needToCompile = YES;
    [self ifAutoCameraMode:[NSNumber numberWithBool:YES]];
}

- (IBAction)unwindCancelPhoto:(UIStoryboardSegue *)segue
{
    [self determineCompilablility];
    [self ifAutoCameraMode:[NSNumber numberWithBool:NO]];
}

- (void)determineCompilablility
{
    // When the user cancels camera - no photo
    if ([self.video.photos count] > 0) {
        if (!self.videoCreator || self.videoCreator.numberOfFramesInLastCompiledVideo != [self.video.photos count]) {
            self.needToCompile = YES;
        } else {
            self.needToCompile = NO;
        }
    } else {
        self.needToCompile = NO;
    }
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
        // Hack to set the height of collectionview right
//        if ([self.video.photos count] == 1) [self.navigationController setToolbarHidden:NO];
        
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.video];
        }
    }
    if ([segue.identifier isEqualToString:@"Edit Corners"]) {
        EditImageViewController *editViewcontroller = (EditImageViewController *)segue.destinationViewController;
        editViewcontroller.delegate = self;
        
        if ([segue.destinationViewController respondsToSelector:@selector(setPhoto:)]) {
            [segue.destinationViewController performSelector:@selector(setPhoto:) withObject:self.selectedPhoto];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setCanvas:)]) {
            [segue.destinationViewController performSelector:@selector(setCanvas:) withObject:self.canvas];
        }
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.video];
        }
        [self.navigationController setToolbarHidden:YES];
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

#pragma mark - Storyboard Actions
- (IBAction)backButtonPressed:(UIBarButtonItem *)sender
{
    [self cleanUpBeforeReturningToGallery];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cleanUpBeforeReturningToGallery
{
    NSLog(@"I'm in clean up\n");
    if ([self.video.photos count] < 1) [Video removeVideo:self.video];
    [self.navigationController setToolbarHidden:NO];
}

#pragma mark - Model

- (void)compileVideo
{
    NSLog(@"I am in compileVideo\n");
    if (self.video && [self.video.photos count] > 0) {
        CGSize size = CGSizeMake(self.navigationController.view.bounds.size.width, self.navigationController.view.bounds.size.height);
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^(){
            typeof(self) strongSelf = weakself;
            if (!strongSelf.videoCreator) strongSelf.videoCreator = [[VideoCreator alloc] initWithVideo:strongSelf.video withScreenSize:size];
            [strongSelf.videoCreator addObserver:strongSelf forKeyPath:@"videoDoneCreating" options:0 context:&videoCompilingDone];
            [strongSelf.videoCreator writeImagesToVideo];
        });
    }
}

- (IBAction)play:sender {
    // Prepare full page video
    if (self.needToCompile || ![[NSFileManager defaultManager] fileExistsAtPath:self.video.compFilePath]) {
        [self compileVideo];
        [self showCompiling];
    } else {
        [self performSegueWithIdentifier:@"Play Full Screen Video" sender:self];
    }
}

- (void)showCompiling {
    [self.playButton setImage:nil];
    [self.playButton setTitle:NSLocalizedString(@"Compiling...", @"Telling the user that the frames are being processed to create a video")];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &videoCompilingDone) {
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^(){
            typeof(self) strongSelf = weakself;
            NSLog(@"Video compilating is %i", self.videoCreator.videoDoneCreating);
            if (strongSelf.videoCreator.videoDoneCreating) {
                // Change the videoModified date - to let Parse know to update the data when convenient
                [strongSelf.video setDateModified:[NSDate date]];
                
                [strongSelf.videoCreator removeObserver:self forKeyPath:@"videoDoneCreating" context:&videoCompilingDone];
                [strongSelf performSegueWithIdentifier:@"Play Full Screen Video" sender:self];
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
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:1 animations:^{
        typeof(self) strongSelf = weakSelf;
        strongSelf.snapshotView.frame = CGRectOffset(strongSelf.snapshotView.frame, 0, -CGRectGetHeight(strongSelf.pickerView.frame));
        strongSelf.pickerView.frame = CGRectOffset(strongSelf.pickerView.frame, 0, -CGRectGetHeight(strongSelf.pickerView.frame));
    }];
}

- (void)prepareFramesPerSecondPickerView
{
    // Create snapshot
    UIView *snapShot = [self createSnapshotView];
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
    [pickerView selectRow:CALCULATE_FPS([self.video.framesPerSecond intValue]) inComponent:0 animated:NO];
    [self.navigationController.view addSubview:pickerView];
    self.pickerView = pickerView;
}

- (UIView *)createSnapshotView
{
    UIView *snapShot = [self.navigationController.view resizableSnapshotViewFromRect:self.navigationController.view.frame afterScreenUpdates:YES withCapInsets:UIEdgeInsetsZero];
    snapShot.frame = self.navigationController.view.frame;
    return snapShot;
}

- (void)removePickerView
{
    // Animation to bring it up
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:1 animations:^{
        typeof(self) strongSelf = weakSelf;
        strongSelf.snapshotView.frame = CGRectOffset(strongSelf.snapshotView.frame, 0, CGRectGetHeight(strongSelf.pickerView.frame));
        strongSelf.pickerView.frame = CGRectOffset(strongSelf.pickerView.frame, 0, CGRectGetHeight(strongSelf.pickerView.frame));
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
    return [NSString stringWithFormat:NSLocalizedString(@"%@ Frames Per Second", @"Frames Per Second"), fpsArray[row]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // perform some action
    NSNumber *framesPerSecond = fpsArray[row];
    [self.video setFramesPerSecond:framesPerSecond];
        
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (error) NSLog(@"An error occurred while trying to save context %@", error);
    }];

    [self setUpFPS];
    self.needToCompile = YES;
}

#pragma mark - UICollectionView Delegate
- (void)selectItemAtIndexPath:(PiecesCollectionCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    self.selectedCellIndexPath = indexPath;
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
            [self chooseCenterCell];
            NSIndexPath *pathForCenterCell = [self.collectionView indexPathForItemAtPoint:CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMidY(self.collectionView.bounds))];
            [self.collectionView scrollToItemAtIndexPath:pathForCenterCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            if (self.centerCell) self.centerCell.maskView.alpha = 0.3;
            self.centerCell.maskView.alpha = 0.0;
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
    if (![photo.cornersDetected boolValue]) NSLog(@"No Corners detected for indexPath: %@\n", indexPath);
    if (![photo.cornersDetected boolValue]) [cell displayWarningBar];
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
    UIAlertView *deleteConfirmButton = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Delete this frame?", @"Ask the user to confirm frame deletion") message:@"" delegate:self cancelButtonTitle:[cancelString capitalizedString] otherButtonTitles:[deleteString capitalizedString], nil];
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
        self.needToCompile = YES;
        [Photo deletePhoto:photo];
        
        [self updateUI];
    }
}

#pragma mark - ViewController Delegates
- (void)popEditImageViewController:(EditImageViewController *)viewController
{
    [self.navigationController popViewControllerAnimated:YES];
    self.needToCompile = YES;
    [self.collectionView reloadItemsAtIndexPaths:@[self.selectedCellIndexPath]];
}

#pragma mark - Update UIs

- (void)updateUI
{
    NSUInteger framesCount = [self.video.photos count]; // This reset toolbar gets called before deletion is completed by NSManagedObjectContext. So this is a hackish way to get around the problem.
    [self showNoFramesScreen:framesCount];
    [self resetToolbarWithPhotoCount:framesCount];
    [self checkIfMoreThanMaxFrames:framesCount];
}

- (void)checkIfMoreThanMaxFrames:(NSUInteger)framesCount
{
    if (framesCount >= MAX_PHOTO_COUNT_PER_VIDEO) {
        [self.cameraButton setEnabled:NO];
        self.autoCameraMode = NO;
    } else {
        [self.cameraButton setEnabled:YES];
    }
}

- (void)showNoFramesScreen:(NSUInteger)frameCount
{
    if (frameCount == 0) {
        [self.noFramesScreen setHidden:NO];
    } else {
        [self.noFramesScreen setHidden:YES];
    }
}

- (void)resetToolbarWithPhotoCount:(NSUInteger)photoCount
{
    if (photoCount > 1) {
        UIImage *playButtonImg = [[UIImage imageNamed:@"PlayButton"]
                                  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [self.navigationController setToolbarHidden:NO animated:NO];
        
        self.playButton.enabled = YES;
        self.playButton.image = playButtonImg;
        
        // Count the number of frames
        [self.noOfFrames setTitle:[NSString stringWithFormat:NSLocalizedString(@"%i count", @"Number of frames in this video"), (int)photoCount]];
    } else {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

@end
