//
//  CMIncoming.m
//  CheckMate
//
//  Created by Rwithu Menon on 12/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMIncoming.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"

@interface CMIncoming () {
    BOOL maskOutgoing;
}

@end

@implementation CMIncoming

- (JSQMessage *)create:(NSDictionary *)item
{
    JSQMessage *message;
    maskOutgoing = [[[PFUser currentUser] objectId] isEqualToString:item[@"userId"]];
    if ([item[@"type"] isEqualToString:@"text"])
        message = [self createTextMessage:item];
    return message;
}

- (JSQMessage *)createTextMessage:(NSDictionary *)item
{
    NSString *name = item[@"name"];
    NSString *userId = item[@"userId"];
    NSDate *date =  item[@"date"];
    NSString *text = item[@"text"];
    return [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date text:text];
}

@end
