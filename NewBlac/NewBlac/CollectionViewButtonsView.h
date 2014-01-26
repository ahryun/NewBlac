//
//  CollectionViewButtonsView.h
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CollectionViewButtonDelegate;

@interface CollectionViewButtonsView : UICollectionReusableView {
    id<CollectionViewButtonDelegate> delegate;
}

@property (nonatomic) id<CollectionViewButtonDelegate> delegate;
+ (NSString *)kind;

@end

@protocol CollectionViewButtonDelegate <NSObject>

// Protocols that this view's delegate needs to implement
- (void)addTapGesture:(UIButton *)button;

@end;
