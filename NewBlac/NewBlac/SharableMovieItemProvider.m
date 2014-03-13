//
//  SharableMovieItemProvider.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/12/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "SharableMovieItemProvider.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation SharableMovieItemProvider

- (id)item
{
    NSURL * videoURL = [NSURL fileURLWithPath:self.videoPath];
    
    return videoURL;
}

- (id)activityViewController:(UIActivityViewController *)activityViewController
          itemForActivityType:(NSString *)activityType
{
    if ( [activityType isEqualToString:UIActivityTypePostToTwitter] )
        return [self item];
    if ( [activityType isEqualToString:UIActivityTypePostToFacebook] )
        return [self item];
    if ( [activityType isEqualToString:UIActivityTypeMessage] )
        return [self item];
    if ( [activityType isEqualToString:UIActivityTypeMail] )
        return [self item];
    return nil;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    NSURL *placeholderURL = [[NSURL alloc] initFileURLWithPath:self.videoPath];
    return placeholderURL;
}

@end
