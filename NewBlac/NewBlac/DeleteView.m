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
    if (self) {
        // Custom initialization
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"delete_image" ofType:@"png"];
        UIImage *deleteImage = [[UIImage alloc] initWithContentsOfFile:imagePath];
        [self setImage:deleteImage];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
//    
//}

@end
