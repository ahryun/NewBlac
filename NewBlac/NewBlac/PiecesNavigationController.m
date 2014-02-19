//
//  PiecesNavigationController.m
//  NewBlac
//
//  Created by Ahryun Moon on 2/18/14.
//  Copyright (c) 2014 Ahryun Moon. All rights reserved.
//

#import "PiecesNavigationController.h"

@interface PiecesNavigationController ()

@end

@implementation PiecesNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // Setting the attributes of the title in Navigation Bar
    NSDictionary *titleTextAttributes = [NSDictionary dictionaryWithObjects:@[[UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f], [UIColor whiteColor]] forKeys:@[NSFontAttributeName, NSForegroundColorAttributeName]];
    [self.navigationBar setTitleTextAttributes:titleTextAttributes];
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavigationBarTile"] forBarMetrics:UIBarMetricsDefault];
    [self.toolbar setBackgroundImage:[UIImage imageNamed:@"ToolBarTile"] forToolbarPosition:UIBarPositionBottom barMetrics:UIBarMetricsDefault];

}

@end
