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
#import "Config.h"
#import "CMUserTrackingViewController.h"

@interface AppDelegate ()<TrnqlDelegate> {
    BOOL saveCalled;
}

@property (assign) BOOL loggedIn;
@property (strong, nonatomic) id<SINClient> sinchClient;
@property (strong, nonatomic) id<SINMessageClient> sinchMessageClient;

@end

@implementation AppDelegate

@synthesize sinchMessageClient;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self enableLocationServices];
    
    saveCalled = NO;
    
    //Start all services
    [self setAPIKeys];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.loggedIn = [[userDefaults objectForKey:@"loggedIn"] boolValue];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"loggedIn"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    NSLog(@"logged in : %d, current usr: %@",self.loggedIn,[PFUser currentUser]);
    //Check if already logged in
    if (self.loggedIn){
        self.currentUser = [PFUser currentUser];
        if (!self.currentUser) {
            NSString *username = [userDefaults objectForKey:@"username"];
            NSString *password = [userDefaults objectForKey:@"password"];
            [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                if (!error) {
                    self.currentUser = user;
                    [self initSinchAndNavigate];
                }
            }];
        } else {
            [self initSinchAndNavigate];
        }
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

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context
{
    if([keyPath isEqual:@"loggedIn"])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        self.loggedIn = [[userDefaults objectForKey:@"loggedIn"] boolValue];
        if (self.loggedIn) {
            self.currentUser = [PFUser currentUser];
        } else {
            self.currentUser = nil;
        }
    }
}

- (void) setAPIKeys {
    Trnql *trnql = [Trnql sharedInstance];
    [trnql setAPIKey:@"2fd6f698-1e43-40dc-a054-b45febcd5c8d"];
    [trnql setDelegate:self];
    [trnql startAllServices];
    
    [Parse enableLocalDatastore];
    [Parse setApplicationId:PARSE_APPLICATION_ID clientKey:PARSE_CLIENT_KEY];
    
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
}

- (void) initSinchAndNavigate {
    [self initSinchClient:self.currentUser[@"username"]];
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    
    CMUserTrackingViewController *userTrackingView  = [mainStoryboard instantiateViewControllerWithIdentifier:@"CMUserTrackingViewController"];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:userTrackingView];
    [navController.navigationBar setBarTintColor:[UIColor colorWithRed:0.416f green:0.800f blue:0.796f alpha:1.00f]];
    navController.navigationBar.translucent = NO;
    navController.navigationBar.topItem.title = @"CheckMate";
    [self.window setRootViewController:navController];
}

- (void) enableLocationServices {
    BOOL locationAllowed = [CLLocationManager locationServicesEnabled];
    
    if (locationAllowed==NO) {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Error"
                                      message:@"An error occured.. Please try again"
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:
                             ^(UIAlertAction * action) {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
        [alert addAction:ok];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark TrnqlDelegate Methods

- (void)smartAddressChange:(AddressEntry * __nullable)address error:(NSError * __nullable)error {
    if (!address) {
        return;
    }
    if (self.loggedIn) {
        NSString *newAddress = [address getAddress];
        self.currentUser[@"address"] = newAddress;
        [self.currentUser saveInBackground];
    }
}

- (void)smartLocationChange:(LocationEntry * __nullable)location error:(NSError * __nullable)error {
    if (!location) {
        return;
    }
    if (self.loggedIn) {
        CLLocation *locationReceived = [location getLocation];
        CLLocationCoordinate2D coordinate = locationReceived.coordinate;
        self.currentUser[@"latitude"] = [NSString stringWithFormat:@"%f",coordinate.latitude];
        self.currentUser[@"longitude"] = [NSString stringWithFormat:@"%f",coordinate.longitude];
        [self.currentUser saveInBackground];
    }
}

- (void)smartActivityChange:(ActivityEntry * __nullable)userActivity error:(NSError * __nullable)error {
    if (!userActivity) {
        return;
    }
    if (self.loggedIn) {
        NSString *activityReceived = [userActivity getActivityString];
        self.currentUser[@"activity"] = activityReceived;
        [self.currentUser saveInBackground];
    }
}


#pragma mark Functional methods

- (void)sendTextMessage:(NSString *)messageText toRecipients:(NSArray *)recipientIDs {
    SINOutgoingMessage *outgoingMessage = [SINOutgoingMessage messageWithRecipients:recipientIDs text:messageText];
    [self.sinchClient.messageClient sendMessage:outgoingMessage];
     saveCalled = NO;
}

// Initialize the Sinch client
- (void)initSinchClient:(NSString*)userId {
    self.sinchClient = [Sinch clientWithApplicationKey:SINCH_APPLICATION_KEY
                                     applicationSecret:SINCH_APPLICATION_SECRET
                                       environmentHost:SINCH_ENVIRONMENT_HOST
                                                userId:userId];
    NSLog(@"Sinch version: %@, userId: %@", [Sinch version], [self.sinchClient userId]);
    
    [self.sinchClient setSupportMessaging:YES];
    [self.sinchClient start];
    [self.sinchClient startListeningOnActiveConnection];
    [self.sinchClient setSupportActiveConnectionInBackground:YES];
     self.sinchClient.delegate = self;
}

- (void)saveMessagesOnParse:(id<SINMessage>)message{
    saveCalled = YES;
    PFObject *messageObject = [PFObject objectWithClassName:@"ChatMessage"];
    
    messageObject[@"messageId"] = [message messageId];
    messageObject[@"userId"] = [self.currentUser objectId];
    messageObject[@"name"] = self.currentUser[@"name"];
    messageObject[@"text"] = [message text];
    messageObject[@"timestamp"] = [message timestamp];
    messageObject[@"secret"] = self.currentUser[@"secret"];

    PFQuery *query = [PFQuery queryWithClassName:@"ChatMessage"];
    [query whereKey:@"messageId" equalTo:[message messageId]];
        
    [query findObjectsInBackgroundWithBlock:^(NSArray *messageArray, NSError *error) {
        if (!error) {
            // If the SinchMessage is not already saved on Parse (an empty array is returned), save it.
            if ([messageArray count] <= 0) {
                [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:SINCH_MESSAGE_SENT object:
                         self userInfo:@{@"message" : messageObject}];
                    }
                }];
            }
        } else {
            NSLog(@"Error: %@", error.description);
        }
    }];
}

-(void) retrieveMessageFromParse:(id<SINMessage>)message {
    PFQuery *query = [PFQuery queryWithClassName:@"ChatMessage"];
    [query whereKey:@"messageId" equalTo:[message messageId]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *messageArray, NSError *error) {
        if (!error) {
            if ([messageArray count] > 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SINCH_MESSAGE_SENT object:self userInfo:@{@"message" : [messageArray firstObject]}];
            } else {
                PFQuery *query = [PFUser query];
                [query whereKey:@"username" equalTo:[message senderId]];
                [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (!error && objects.count>0) {
                        PFObject *messageObject = [PFObject objectWithClassName:@"ChatMessage"];
                        
                        messageObject[@"messageId"] = [message messageId];
                        messageObject[@"userId"] = [[objects firstObject] objectId];
                        messageObject[@"name"] = [objects firstObject][@"name"];
                        messageObject[@"text"] = [message text];
                        messageObject[@"timestamp"] = [message timestamp];
                        messageObject[@"secret"] = self.currentUser[@"secret"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:SINCH_MESSAGE_SENT object:self userInfo:@{@"message" : messageObject}];
                    }
                }];
            }
        }
    }];
}

#pragma mark SINClientDelegate methods

- (void)clientDidStart:(id<SINClient>)client {
    NSLog(@"Start SINClient successful!");
    self.sinchMessageClient = [self.sinchClient messageClient];
    self.sinchMessageClient.delegate =  self;
}

- (void)clientDidFail:(id<SINClient>)client error:(NSError *)error {
    NSLog(@"Start SINClient failed. Description: %@. Reason: %@.", error.localizedDescription, error.localizedFailureReason);
}

#pragma mark SINMessageClientDelegate methods

// Receiving an incoming message.
- (void)messageClient:(id<SINMessageClient>)messageClient didReceiveIncomingMessage:(id<SINMessage>)message {
    [self retrieveMessageFromParse:message];
}

// Finish sending a message
- (void)messageSent:(id<SINMessage>)message recipientId:(NSString *)recipientId {
    if (!saveCalled) {
        [self saveMessagesOnParse:message];
    }
}

// Failed to send a message
- (void)messageFailed:(id<SINMessage>)message info:(id<SINMessageFailureInfo>)messageFailureInfo {
    [[NSNotificationCenter defaultCenter] postNotificationName:SINCH_MESSAGE_FAILED object:self userInfo:@{@"message" : message}];
    NSLog(@"MessageBoard: message to %@ failed. Description: %@. Reason: %@.", messageFailureInfo.recipientId, messageFailureInfo.error.localizedDescription, messageFailureInfo.error.localizedFailureReason);
}

-(void)messageDelivered:(id<SINMessageDeliveryInfo>)info
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SINCH_MESSAGE_DELIVERED object:info];
}

@end
