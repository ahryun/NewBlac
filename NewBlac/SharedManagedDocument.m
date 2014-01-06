//
//  SharedManagedDocument.m
//  FlickrCD
//
//  Created by Ahryun Moon on 11/11/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "SharedManagedDocument.h"

@interface SharedManagedDocument()

@property (nonatomic, strong) TroubleshootManagedDocument *sharedDocument;

@end

@implementation SharedManagedDocument

+ (SharedManagedDocument *)sharedInstance
{
    static SharedManagedDocument *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"Demo Document"];
        self.sharedDocument = [[TroubleshootManagedDocument alloc] initWithFileURL:url];
    }
    return self;
}

- (void)performWithDocument:(OnDocumentReady)onDocumentReady
{
    void (^OnDocumentDidLoad)(BOOL) = ^(BOOL success) {
        onDocumentReady(self.sharedDocument);
    };
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.sharedDocument.fileURL path]]) {
        [self.sharedDocument saveToURL:self.sharedDocument.fileURL
                forSaveOperation:UIDocumentSaveForCreating
               completionHandler:OnDocumentDidLoad];
    } else if (self.sharedDocument.documentState == UIDocumentStateClosed) {
        [self.sharedDocument openWithCompletionHandler:OnDocumentDidLoad];
    } else if (self.sharedDocument.documentState == UIDocumentStateNormal) {
        OnDocumentDidLoad(YES);
    }
}

@end
