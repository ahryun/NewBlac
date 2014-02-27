//
//  PiecesCollectionCell.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoPlayView.h"

@protocol ScrollingCellDelegate;

@interface PiecesCollectionCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, weak) id<ScrollingCellDelegate> delegate;

- (void)displayVideo;
- (void)prepareScrollView;
- (void)reset;

@end

@protocol ScrollingCellDelegate <NSObject>

- (void)scrollingCellDidBeginPulling:(PiecesCollectionCell *)cell;
- (void)deleteButtonPressed:(PiecesCollectionCell *)cell;
- (void)selectItemAtIndexPath:(PiecesCollectionCell *)cell;

@end

