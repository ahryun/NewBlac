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

@interface VideosCollectionViewController ()

@property (nonatomic, strong) Video *selectedVideo;

@end

@implementation VideosCollectionViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeFetchedResultsController];
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"View And Edit Video"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setVideo:)]) {
            [segue.destinationViewController performSelector:@selector(setVideo:) withObject:self.selectedVideo];
        }
    }
}

- (IBAction)addNewVideo:(UIButton *)sender {
    
    self.selectedVideo = [Video videoWithPath:nil inManagedObjectContext:self.managedObjectContext];
    // Do manual segue "View And Edit Video"
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
    VideoCollectionCell *cell = (VideoCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Playable Video" forIndexPath:indexPath];
    
    Video *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSURL *videoURL = [NSURL fileURLWithPath:video.compFilePath];
    [cell setVideoURL:videoURL];
    
    return cell;
}

@end
