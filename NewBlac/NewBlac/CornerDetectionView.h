//
//  CornerDetectionView.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/7/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CornerDetectionViewDelegate <NSObject>

- (void)displayCorners;

@end

@interface CornerDetectionView : UIView {
    id<CornerDetectionViewDelegate> delegate;
}

@property (nonatomic, strong) id<CornerDetectionViewDelegate> delegate;


@end
