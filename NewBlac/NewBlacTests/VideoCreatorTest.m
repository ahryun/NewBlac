//
//  VideoCreatorTest.m
//  NewBlac
//
//  Created by Ahryun Moon on 3/26/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VideoCreator.h"
#import "Video+LifeCycle.h"

@interface VideoCreatorTest : XCTestCase

@property (nonatomic, strong) VideoCreator *videoCreator;

@end

@implementation VideoCreatorTest

- (void)setUp
{
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.videoCreator = [[VideoCreator alloc] init];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testImageRatioCalc
{
    CGSize screenSize = CGSizeMake(320.f, 480.f);
    
    // When originalImageRatio is larger than maxRatio allowed by Facebook
    float originalImageRatio = 150.f / 80.f;
    XCTAssertEqual([self.videoCreator getImageSizewithScreenSize:screenSize withImageSize:originalImageRatio].width, 320.f, @"Image width calculated incorrectly\n");
    XCTAssertEqual([self.videoCreator getImageSizewithScreenSize:screenSize withImageSize:originalImageRatio].height, 180.f, @"Image height calculated incorrectly\n");
    
    // When originalImageRatio is smaller than minRatio allowed by Facebook
    originalImageRatio = 10.f / 80.f;
    XCTAssertEqual([self.videoCreator getImageSizewithScreenSize:screenSize withImageSize:originalImageRatio].width, 270.f, @"Image width calculated incorrectly\n");
    XCTAssertEqual([self.videoCreator getImageSizewithScreenSize:screenSize withImageSize:originalImageRatio].height, 480.f, @"Image height calculated incorrectly\n");
    
    // When originalImageRatio is in between minRatio and maxRatio allowed by Facebook
    originalImageRatio = 50.f / 80.f;
    XCTAssertEqual([self.videoCreator getImageSizewithScreenSize:screenSize withImageSize:originalImageRatio].width, 300.f, @"Image width calculated incorrectly\n");
    XCTAssertEqual([self.videoCreator getImageSizewithScreenSize:screenSize withImageSize:originalImageRatio].height, 480.f, @"Image height calculated incorrectly\n");
}

@end
