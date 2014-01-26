//
//  CollectionViewButtonsView.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "CollectionViewButtonsView.h"

@implementation CollectionViewButtonsView

const NSString *addVideoString = @"AddVideo";
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setFrame:CGRectMake(0, 0, 100.0, 50.0)];
        [button setBackgroundColor:[UIColor whiteColor]];
        [button setTitle:@"Add a video" forState:UIControlStateNormal];
        [self.delegate addTapGesture:button];
        [self addSubview:button];
    }
    return self;
}

+ (NSString *)kind
{
    return (NSString *)addVideoString;
}

@end
