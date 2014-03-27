//
//  CollectionViewLayout.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/25/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "CollectionViewLayout.h"
#import "Strings.h"

@interface CollectionViewLayout()

@property (nonatomic) NSDictionary *layoutInformation;
@property (nonatomic) NSInteger maxNumRows;
@property (nonatomic) NSInteger x_inset;
@property (nonatomic) NSInteger y_inset;

@end

@implementation CollectionViewLayout

#pragma mark - cells, header/footer, decoration views layout
- (NSInteger)x_inset
{
    return (self.collectionView.frame.size.width - CELL_WIDTH) / 2;
}

- (NSInteger)y_inset
{
    return (self.collectionView.frame.size.height - CELL_HEIGHT) / 2;
}

// Do all the calculations for cells, header/footer, decoration views
- (void)prepareLayout
{
    NSLog(@"I'm in prepareLayout\n");
    [super prepareLayout];
    
    NSMutableDictionary *layoutInformation = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellInformation = [NSMutableDictionary dictionary];
    NSIndexPath *indexPath;
    NSInteger numSections = [self.collectionView numberOfSections];
    NSInteger totalWidth = self.x_inset;
    
    // Main cell attributes
    for (NSInteger section = 0; section < numSections; section++) {
        NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
        for (NSInteger item = 0; item < numItems; item++){
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            [cellInformation setObject:attributes forKey:indexPath];
        }
    }
    for (NSInteger section = numSections - 1; section >= 0; section--) {
        NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
        for(NSInteger item = 0; item < numItems; item++){
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [cellInformation objectForKey:indexPath]; // 1
            attributes.frame = [self frameForCellAtIndexPath:indexPath withTotalWidth:totalWidth];
            cellInformation[indexPath] = attributes;
            totalWidth += attributes.frame.size.width + X_SPACING;
        }
        if(section == 0) self.maxNumRows = totalWidth; // 4
    }
    [layoutInformation setObject:cellInformation forKey:@"VideoCells"]; // 5
    self.layoutInformation = layoutInformation;
    NSLog(@"Content size is %li\n", (long)self.maxNumRows);
}

// Return attributes of all items (cells, supplementary views, decoration views) that appear within this rect
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSLog(@"I'm in layoutAttributesForElementsInRect\n");
    NSMutableArray *myAttributes = [NSMutableArray arrayWithCapacity:self.layoutInformation.count];
    for(NSString *key in self.layoutInformation){
        NSDictionary *attributesDict = [self.layoutInformation objectForKey:key];
        for(NSIndexPath *key in attributesDict){
            UICollectionViewLayoutAttributes *attributes =
            [attributesDict objectForKey:key];
            if(CGRectIntersectsRect(rect, attributes.frame)){
                [myAttributes addObject:attributes];
            }
        }
    }
    return myAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    UIScrollView *scrollView = self.collectionView;
    CGFloat delta = newBounds.origin.x - scrollView.bounds.origin.x;
    for (UIAttachmentBehavior *spring in self.dynamicAnimator.behaviors) {
        UICollectionViewLayoutAttributes *item = [spring.items firstObject];
        CGPoint center = item.center;
        center.x += delta;
        item.center = center;
        
        [self.dynamicAnimator updateItemUsingCurrentState:item];
    }
    
    return NO;
}

- (CGRect)frameForCellAtIndexPath:(NSIndexPath *)indexPath withTotalWidth:(NSInteger)totalWidth
{
    CGRect rect = CGRectZero;
    rect.origin.x = totalWidth;
    rect.origin.y = self.y_inset + (indexPath.section) * (self.y_inset + CELL_HEIGHT);
    rect.size.width = CELL_WIDTH;
    rect.size.height = self.collectionView.frame.size.height - self.y_inset;
    
    return rect;
}

- (CGSize)collectionViewContentSize {
    CGFloat width = self.maxNumRows + (self.x_inset - X_SPACING);
    CGFloat height = self.collectionView.numberOfSections * self.collectionView.frame.size.height;
    return CGSizeMake(width, height);
}

// Layout attributes for a specific cell
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInformation[@"VideoCells"][indexPath];
}

@end
