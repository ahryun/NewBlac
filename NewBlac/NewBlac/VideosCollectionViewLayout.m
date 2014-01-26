//
//  VideosCollectionViewLayout.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/25/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideosCollectionViewLayout.h"
#import "CollectionViewButtonsView.h"

@implementation VideosCollectionViewLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self registerClass:[CollectionViewButtonsView class] forDecorationViewOfKind:[CollectionViewButtonsView kind]];
    }
    return self;
}

#pragma mark - cells, header/footer, decoration views layout

// Do all the calculations for cells, header/footer, decoration views
- (void)prepareLayout
{
    [super prepareLayout];
    
}

// Return attributes of all items (cells, supplementary views, decoration views) that appear within this rect
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [[NSMutableArray alloc] initWithCapacity:4];
    
    [allAttributes addObject:[self layoutAttributesForDecorationViewOfKind:@"AddVideo" atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]];
    
    for (NSInteger i = 0; i < [self.collectionView numberOfItemsInSection:0]; i++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        [allAttributes addObject:layoutAttributes];
    }
    return allAttributes;
}

// Layout attributes for a specific cell
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    attributes.zIndex = 1;
    return attributes;
}

// layout attributes for a specific decoration view
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:decorationViewKind withIndexPath:indexPath];
    NSLog(@"Collection view content size width is %f and height is %f\n", self.collectionViewContentSize.width, self.collectionViewContentSize.height);
    layoutAttributes.frame = CGRectMake(0.0, 0.0, self.collectionViewContentSize.width, self.collectionViewContentSize.height);
    layoutAttributes.zIndex = 2;
    return layoutAttributes;
}

// layout attributes for a specific header or footer
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    return attributes;
}

@end
