//
//  CollectionViewButtonsView.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/24/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "CollectionViewButtonsView.h"

@implementation CollectionViewButtonsView

const NSString *addVideoKind = @"AddVideo";

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self setBackgroundColor:[UIColor whiteColor]];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Add a Video" forState:UIControlStateNormal];
    [button setFrame:self.frame];
    [self addSubview:button];
    return self;
}

+ (NSString *)kind
{
    return (NSString *)addVideoKind;
}

@end
