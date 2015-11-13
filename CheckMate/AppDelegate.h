//
//  AppDelegate.h
//  CheckMate
//
//  Created by Rwithu Menon on 01/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Sinch/Sinch.h>
#import <Parse/Parse.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,SINClientDelegate,SINMessageClientDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) PFUser* currentUser;
- (void)initSinchClient:(NSString*)userId;
- (void)sendTextMessage:(NSString *)messageText toRecipients:(NSArray *)recipientIDs;

@end

