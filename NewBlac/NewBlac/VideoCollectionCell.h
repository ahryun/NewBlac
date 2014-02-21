//
//  VideoCollectionCell.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScrollingCellDelegate;

@interface VideoCollectionCell : UICollectionViewCell

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, weak) id<ScrollingCellDelegate> delegate;

- (void)displayVideo;
- (void)prepareScrollView;
- (void)reset;

@end

@protocol ScrollingCellDelegate <NSObject>

- (void)scrollingCellDidBeginPulling:(VideoCollectionCell *)cell;
//- (void)scrollingCell:(VideoCollectionCell *)cell didChangePullOffset:(CGFloat)offset;
//- (void)scrollingDidEndPulling:(VideoCollectionCell *)cell;
- (void)deleteButtonPressed:(VideoCollectionCell *)cell;

@end

