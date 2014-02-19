//
//  DeleteView.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/30/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "DeleteView.h"

@implementation DeleteView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    NSLog(@"I'm trying to draw the x button\n");
    if (self) {
        // Initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    NSLog(@"I'm in initWithCoder\n");
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
//}

@end
