//
//  CMOutgoing.m
//  CheckMate
//
//  Created by Rwithu Menon on 12/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMOutgoing.h"
#import <Parse/Parse.h>

#import "AppDelegate.h"

@implementation CMOutgoing

- (void)send:(NSString *)text withRecipients:(NSMutableArray *)recipients
{
    if (text != nil) {
        NSMutableArray *usernames = [[NSMutableArray alloc] init];
        for (PFUser *user in recipients) {
            [usernames addObject:user[@"username"]];
        }
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate sendTextMessage:text toRecipients:usernames];
    }
}

@end
