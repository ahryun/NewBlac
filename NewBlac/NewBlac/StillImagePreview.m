//
//  Created by Ahryun Moon on 11/20/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//


#import "StillImagePreview.h"
#import <AVFoundation/AVFoundation.h>

@implementation StillImagePreview

+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
	return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[previewLayer setSession:session];
}

@end
