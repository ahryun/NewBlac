//
//  CornerDetectionView.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/7/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CornerDetectionViewDelegate;

@interface CornerDetectionView : UIView {
    id<CornerDetectionViewDelegate> delegate;
}

@property (nonatomic) id<CornerDetectionViewDelegate> delegate;
- (void)reloadData;
- (void)reloadDataInRect:(CGRect)rect;

@end

@protocol CornerDetectionViewDelegate <NSObject>

- (UIBezierPath *)drawPathInView:(CornerDetectionView *)view atIndex:(NSUInteger)index;
- (UIColor *)fillColorInView:(CornerDetectionView *)view;
- (NSUInteger)numberOfCornersInView:(CornerDetectionView *)view;

@end


