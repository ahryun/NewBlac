//
//  VideosCollectionViewController.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "CoreDataCollectionViewController.h"
#import "VideoCollectionCell.h"

@interface VideosCollectionViewController : CoreDataCollectionViewController <UICollectionViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDataSource,
    UIGestureRecognizerDelegate>

@property (nonatomic, strong) VideoCollectionCell *centerCell;

@end
