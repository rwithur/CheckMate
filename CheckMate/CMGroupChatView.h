//
//  CMGroupChatView.h
//  CheckMate
//
//  Created by Rwithu Menon on 12/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "JSQMessagesViewController.h"
#import <Parse/Parse.h>

@interface CMGroupChatView : JSQMessagesViewController

@property (strong, nonatomic) PFUser *currentUser;

@end
