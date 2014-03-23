//
//  PiecesCollectionCell.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "PiecesCollectionCell.h"
#import <AVFoundation/AVFoundation.h>

@interface PiecesCollectionCell() <UIScrollViewDelegate>

@property (nonatomic) BOOL pulling;

@end

@implementation PiecesCollectionCell

// Since the cell is registered through Storyboard, I need to use initWithCoder instead of initWithFrame
- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSLog(@"Hey I'm in initWithCoder\n");

    self = [super initWithCoder:aDecoder];
    if (self) {
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.clipsToBounds = NO;
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        scrollView.delaysContentTouches = YES;
        scrollView.delegate = self;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectCell)];
        [scrollView addGestureRecognizer:tapGesture];
        
        [self.contentView addSubview:scrollView];
        self.scrollView = scrollView;
        self.pulling = NO;
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.warningLabel removeFromSuperview];
    [self resetWithoutAnimation];
}

#define OFFSET_TOP               (80)
#define PULL_THRESHOLD           (50)
#define CELL_HEIGHT              (330)

- (void)prepareScrollView
{
    NSLog(@"I'm in prepareScrollView\n");
    // Set up scroll view
    [self.scrollView setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self.scrollView setContentSize:CGSizeMake(self.bounds.size.width, self.bounds.size.height + OFFSET_TOP)];
    [self.scrollView setContentOffset:CGPointMake(0, OFFSET_TOP)];
    
    // Set up delete button within scroll view programmatically
    if (!self.deleteButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 10, self.scrollView.frame.size.width, 60);
        NSString *deleteString = NSLocalizedString(@"delete", @"Action button to delete a piece of data");
        [button setTitle:[[NSString stringWithFormat:@" %@", deleteString] uppercaseString] forState:UIControlStateNormal];
        [button setTintColor:[UIColor whiteColor]];
        [button.layer setCornerRadius:5.0f];
        UIImage *scissorImage = [UIImage imageNamed:@"DeleteIcon"];
        scissorImage = [scissorImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button setImage:scissorImage forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
        button.alpha = 0;
        [button setBackgroundColor:[UIColor colorWithRed:(240.f/255) green:(101.f/255) blue:(98.f/255) alpha:1.f]];
        self.deleteButton = button;
        [self.scrollView addSubview:button];
        [self.deleteButton addTarget:self action:@selector(sendDeleteMessage) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)sendDeleteMessage
{
    // Tell delegate to delet this video
    [self.delegate deleteButtonPressed:self];
}

- (void)selectCell
{
    [self.delegate selectItemAtIndexPath:self];
}

- (void)displayVideo
{
    if (!self.imageView) {
        UIImageView *imageView = [[UIImageView alloc] init];
        [imageView setFrame:CGRectMake(0, OFFSET_TOP, self.bounds.size.width, CELL_HEIGHT)];
        [imageView.layer setCornerRadius:15.0f];
        imageView.clipsToBounds = YES;
        
        // This makes the video darkened until it's in the middle and playing
        if (!self.maskView) {
            self.maskView = [[UIView alloc] initWithFrame:imageView.bounds];
            self.maskView.backgroundColor = [UIColor blackColor];
            self.maskView.alpha = 0.3;
            [imageView addSubview:self.maskView];
        }
        
        [self.scrollView addSubview:imageView];
        self.imageView = imageView;
    }
}

- (void)displayWarningBar
{
    if (self.imageView) {
        UILabel *warningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.imageView.bounds.size.width, 50.f)];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"WarningSign"];
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        NSMutableAttributedString *mutableAttachmentString = [attachmentString mutableCopy];
        NSAttributedString *myString= [[NSAttributedString alloc] initWithString:NSLocalizedString(@" Snap! No Corners Found", @"This instruction tells the user that a rectangle was not found in the specific frame")];
        [mutableAttachmentString appendAttributedString:myString];
        warningLabel.attributedText = mutableAttachmentString;
        [warningLabel setBackgroundColor:[UIColor colorWithRed:(0.f/255.f) green:(0.f/255.f) blue:(0.f/255.f) alpha:0.7f]];
        [warningLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];
        [warningLabel setTextAlignment:NSTextAlignmentCenter];
        [warningLabel setTextColor:[UIColor lightGrayColor]];
        [self.imageView addSubview:warningLabel];
        self.warningLabel = warningLabel;
    }
}

#pragma mark - ScrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = OFFSET_TOP - self.scrollView.contentOffset.y; // 0 - 80
    if (offset > PULL_THRESHOLD && !self.pulling) {
        self.deleteButton.alpha = offset / OFFSET_TOP;
        [self.delegate scrollingCellDidBeginPulling:self];
        self.pulling = YES;
    }
    if (self.pulling) self.deleteButton.alpha = offset / OFFSET_TOP;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (targetContentOffset->y < (OFFSET_TOP / 2)) {
        *targetContentOffset = CGPointMake(self.scrollView.contentOffset.x, 0);
        self.deleteButton.alpha = 1;
    } else {
        *targetContentOffset = CGPointMake(self.scrollView.contentOffset.x, OFFSET_TOP);
        self.deleteButton.alpha = 0;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        self.pulling = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pulling = NO;
}

#pragma mark - Convenience Functions

- (void)reset
{
    self.pulling = NO;
    [UIView animateWithDuration:0.5 animations:^{
        self.deleteButton.alpha = 0;
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, OFFSET_TOP)];
    }];
}

- (void)resetWithoutAnimation
{
    self.pulling = NO;
    self.deleteButton.alpha = 0;
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, OFFSET_TOP)];
}

@end
