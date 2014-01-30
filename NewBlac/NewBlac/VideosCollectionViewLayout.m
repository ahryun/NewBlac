//
//  VideosCollectionViewLayout.m
//  NewBlac
//
//  Created by Ahryun Moon on 1/25/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "VideosCollectionViewLayout.h"
#import "CollectionViewButtonsView.h"

@interface VideosCollectionViewLayout()

@property (nonatomic) NSDictionary *layoutInformation;
@property (nonatomic) NSArray *headerLayoutInformation;
@property (nonatomic) NSInteger maxNumRows;

@end

@implementation VideosCollectionViewLayout

#define X_SPACING               (10.0)
#define Y_SPACING               (10.0)

#define CELL_WIDTH              (250)
#define CELL_HEIGHT             (250)

- (id)init
{
    self = [super init];
    if (self) {
//        [self registerClass:[CollectionViewButtonsView class] forDecorationViewOfKind:[CollectionViewButtonsView kind]];
        self.headerReferenceSize = CGSizeMake(100, 100);
    }
    return self;
}

#pragma mark - cells, header/footer, decoration views layout

// Do all the calculations for cells, header/footer, decoration views
- (void)prepareLayout
{
    NSLog(@"I'm in prepareLayout\n");
    NSMutableDictionary *layoutInformation = [NSMutableDictionary dictionary];
    NSMutableDictionary *headerLayoutInformation = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellInformation = [NSMutableDictionary dictionary];
    NSIndexPath *indexPath;
    NSInteger numSections = [self.collectionView numberOfSections];
    NSInteger totalWidth = 0;

    // Header Attributes
    UICollectionViewLayoutAttributes *headerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    headerAttributes.frame = CGRectMake(X_SPACING, Y_SPACING, CELL_WIDTH, CELL_HEIGHT);
    headerAttributes.alpha = 0.5;
    NSIndexPath *headerIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    headerLayoutInformation[headerIndexPath] = headerAttributes;
    [layoutInformation setObject:headerLayoutInformation forKey:UICollectionElementKindSectionHeader];
    totalWidth += headerAttributes.frame.size.width + X_SPACING;
    
    // Main cell attributes
    for(NSInteger section = 0; section < numSections; section++){
        NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
        for(NSInteger item = 0; item < numItems; item++){
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            [cellInformation setObject:attributes forKey:indexPath];
        }
    }
    for(NSInteger section = numSections - 1; section >= 0; section--) {
        NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
        for(NSInteger item = 0; item < numItems; item++){
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [cellInformation objectForKey:indexPath]; // 1
            attributes.frame = [self frameForCellAtIndexPath:indexPath withTotalWidth:totalWidth];
            cellInformation[indexPath] = attributes;
            totalWidth += attributes.frame.size.width + X_SPACING;
        }
        if(section == 0){
            self.maxNumRows = totalWidth; // 4
        }
    }
    [layoutInformation setObject:cellInformation forKey:@"VideoCells"]; // 5
    self.layoutInformation = layoutInformation;
    NSLog(@"Content size is %i\n", self.maxNumRows);
}

- (CGRect)frameForCellAtIndexPath:(NSIndexPath *)indexPath withTotalWidth:(NSInteger)totalWidth
{
    CGRect rect = CGRectZero;
    rect.origin.x = totalWidth + X_SPACING;
    rect.origin.y = (CELL_HEIGHT + Y_SPACING) * (indexPath.section) + Y_SPACING;
    rect.size.width = CELL_WIDTH;
    rect.size.height = CELL_HEIGHT;
    
    return rect;
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

- (CGSize)collectionViewContentSize {
    CGFloat width = self.maxNumRows + X_SPACING;
    CGFloat height = self.collectionView.numberOfSections * (CELL_HEIGHT + Y_SPACING) + Y_SPACING;
    return CGSizeMake(width, height);
}

// Layout attributes for a specific cell
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInformation[@"VideoCells"][indexPath];
}

// layout attributes for a specific header or footer
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Kind for supplementary view is %@\n", kind);
    NSLog(@"I'm in layoutAttributesForSupplementaryViewOfKind\n");
    return self.layoutInformation[kind][indexPath];
}

@end
