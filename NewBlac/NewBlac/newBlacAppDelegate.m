//
//  newBlacAppDelegate.m
//  NewBlac
//
//  Created by Ahryun Moon on 11/25/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#import "newBlacAppDelegate.h"
#import <Parse/Parse.h>
#import <Crashlytics/Crashlytics.h>

@interface newBlacAppDelegate()

@end

@implementation newBlacAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
//    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"BackButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"BackButton"]];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"BackButton"]];
    // Parse
    [Parse setApplicationId:@"gsiksRJI1A3BsNSiKYeN8e4AatcFQVeUeTlOQhvJ"
                  clientKey:@"fowYql3KcQxl0lGVumCEshYXgiKJpjUEQ2h5v9oa"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    // Facebook
    [PFFacebookUtils initializeFacebook];
    // Crashlytics
    [Crashlytics startWithAPIKey:@"ece2ac5a141b05d778097923cf3c78a6fb77be1e"];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

@end
