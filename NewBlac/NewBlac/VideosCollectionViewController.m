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
#import "VideosCollectionViewLayout.h"
#import "CollectionViewButtonsView.h"

@interface VideosCollectionViewController ()

@property (nonatomic, strong) Video *selectedVideo;

@end

@implementation VideosCollectionViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeFetchedResultsController];
    self.collectionView.collectionViewLayout = [[VideosCollectionViewLayout alloc] init];
    [self.collectionView registerClass:[VideoCollectionCell class] forCellWithReuseIdentifier:@"Playable Video"];
//    [self.collectionView registerClass:[CollectionViewButtonsView class] forSupplementaryViewOfKind:[CollectionViewButtonsView kind] withReuseIdentifier:@"Add a Video"];
}

- (IBAction)addVideo:(UIButton *)sender {
    self.selectedVideo = [Video videoWithPath:nil inManagedObjectContext:self.managedObjectContext];
    // Do manual segue "View And Edit Video"
    [self performSegueWithIdentifier:@"View And Edit Video" sender:self];
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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
    // Fix the following
//    self.selectedVideo = [[self.collectionView cellForItemAtIndexPath:indexPath] getVideo];
    // Do manual segue "View And Edit Video"
    [self performSegueWithIdentifier:@"View and Edit Video" sender:self];
}

#pragma mark - NSFetchedResultsController
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"I'm in cellForItemAtIndexPath\n");
    VideoCollectionCell *cell = (VideoCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Playable Video" forIndexPath:indexPath];
    
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSURL *videoURL = [NSURL fileURLWithPath:video.compFilePath];
    [cell setVideoURL:videoURL];
    
    return cell;
}

//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
//{
//    NSLog(@"Kind is %@\n", kind);
//    CollectionViewButtonsView *buttonView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Add a Video" forIndexPath:indexPath];
//    return buttonView;
//}



@end
