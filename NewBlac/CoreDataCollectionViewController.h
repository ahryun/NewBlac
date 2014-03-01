//
//  CoreDataCollectionViewController.h
//  FlickrCD
//
//  Created by Ahryun Moon on 11/4/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface CoreDataCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL showPhotos;
@property (nonatomic, strong) NSManagedObject *specificModel;

@property (nonatomic, strong) NSString *entityNameOfInterest;
@property (nonatomic, strong) NSString *propertyNameOfInterest;
@property (nonatomic, strong) NSString *cacheNameOfInterest;
- (void)initializeFetchedResultsController;

@end
