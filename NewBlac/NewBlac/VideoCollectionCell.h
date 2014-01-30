//
//  VideoCollectionCell.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoCollectionCell : UICollectionViewCell

@property (nonatomic, strong) NSURL *videoURL;
//@property (nonatomic, weak) UIView *deleteView;
- (void)displayVideo;

@end
