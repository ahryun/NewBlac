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
        url = [url URLByAppendingPathComponent:@"NewBlacPersistentStore"];
        self.sharedDocument = [[TroubleshootManagedDocument alloc] initWithFileURL:url];
        
    }
    return self;
}

- (void)performWithDocument:(OnDocumentReady)onDocumentReady
{
    void (^OnDocumentDidLoad)(BOOL) = ^(BOOL success) {
        NSLog(@"success = %hhd", success);
        onDocumentReady(self.sharedDocument);
    };
    NSLog(@"I'm in trying to make the uimanageddocument\n");
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.sharedDocument.fileURL path]]) {
        NSLog(@"Shared document does not exist\n");
        [self.sharedDocument saveToURL:self.sharedDocument.fileURL
                forSaveOperation:UIDocumentSaveForCreating
               completionHandler:OnDocumentDidLoad];
    } else if (self.sharedDocument.documentState == UIDocumentStateClosed) {
        NSLog(@"Shared document status is closed\n");
        [self.sharedDocument openWithCompletionHandler:OnDocumentDidLoad];
    } else if (self.sharedDocument.documentState == UIDocumentStateNormal) {
        NSLog(@"Shared document status is normal\n");
        OnDocumentDidLoad(YES);
    } else if (self.sharedDocument.documentState == UIDocumentStateSavingError) {
        NSLog(@"Hey There is a problem saving document");
    }
}

@end
