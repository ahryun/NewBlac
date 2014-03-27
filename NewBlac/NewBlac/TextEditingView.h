//
//  TextEditingView.h
//  NewBlac
//
//  Created by Ahryun Moon on 3/27/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TextEditingViewDelegate;

@interface TextEditingView : UIView {
    id<TextEditingViewDelegate> delegate;
}

@property (nonatomic) id<TextEditingViewDelegate> delegate;
@property (nonatomic, strong) UIImage *videoImage;
@property (nonatomic, strong) NSString *existingTitle;
- (void)setVideoImage:(UIImage *)videoImage;

@end

@protocol TextEditingViewDelegate <NSObject>

- (void)dismissTextEditingViewDelegate:(TextEditingView *)view;
- (void)saveTitle:(NSString *)newTitle;

@end

