#import "Kiwi.h"
#import "VideosCollectionViewController.h"

SPEC_BEGIN(VideoCollectionView)

describe(@"VideoCollectionView behaves well", ^{
    
    __block VideoCollectionView *videoCollectionView;
    
    beforeEach(^{
        
        videoCollectionView = [[VideoCollectionView alloc] init];
        
    });
    
    afterEach(^{
        
        videoCollectionView = nil;
    });
    
    it(@"add method should exist", ^{
        
        
    });
    
});

SPEC_END