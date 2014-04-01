//
//  NewBlacKiwiTests.m
//  NewBlacKiwiTests
//
//  Created by Ahryun Moon on 4/1/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VideoCreator.h"
#import "Video+LifeCycle.h"

#define MR_SHORTHAND
#import "CoreData+MagicalRecord.h"

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

@interface NewBlacKiwiTests : XCTestCase

@property (nonatomic, strong) VideoCreator *videoCreator;

@end

@implementation NewBlacKiwiTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.videoCreator = [[VideoCreator alloc] init];
    
    [MagicalRecord setDefaultModelFromClass:[self class]];
	[MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void)tearDown
{
    [MagicalRecord cleanUp];
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
