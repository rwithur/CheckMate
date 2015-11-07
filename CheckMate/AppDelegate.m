//
//  AppDelegate.m
//  CheckMate
//
//  Created by Rwithu Menon on 01/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <trnql/trnql.h>

#import "AppDelegate.h"
#import "CMUserTrackingViewController.h"

@interface AppDelegate ()<TrnqlDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    self.loggedIn = YES;
    Trnql *trnql = [Trnql sharedInstance];
    [trnql setAPIKey:@"2fd6f698-1e43-40dc-a054-b45febcd5c8d"];
    [trnql setDelegate:self];
    [trnql startAllServices];

    // Override point for customization after application launch.
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"XFhZww2w6u8F25XYqxmR9kNNJ1E12xhA6nQAdlUb" clientKey:@"7JnCGflBds32nAr7VUhAf4SkATlKJ6CGAX5o4vJk"];
    
    PFACL *defaultACL = [PFACL ACL];
    
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    if (self.loggedIn) {
        CMUserTrackingViewController *userTrackingView = [[CMUserTrackingViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:userTrackingView];
        [navController.navigationBar setBarTintColor:[UIColor colorWithRed:0.416f green:0.800f blue:0.796f alpha:1.00f]];
        navController.navigationBar.translucent = NO;
        navController.navigationBar.topItem.title = @"CheckMate";
        [self.window setRootViewController:navController];
    } 
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)smartAddressChange:(AddressEntry * __nullable)address error:(NSError * __nullable)error {
    if (self.loggedIn) {
        NSString *newAddress = [address getAddress];
        PFUser *currentUser = [PFUser currentUser];
        currentUser[@"address"] = newAddress;
        [currentUser save];
    }
}

- (void)smartLocationChange:(LocationEntry * __nullable)location error:(NSError * __nullable)error {
    if (self.loggedIn) {
        PFUser *currentUser = [PFUser currentUser];
        CLLocation *locationReceived = [location getLocation];
        CLLocationCoordinate2D coordinate = locationReceived.coordinate;
        currentUser[@"latitude"] = [NSString stringWithFormat:@"%f",coordinate.latitude];
        currentUser[@"longitude"] = [NSString stringWithFormat:@"%f",coordinate.longitude];
        [currentUser save];
    }
}

@end
