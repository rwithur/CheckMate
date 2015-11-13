//
//  CMUserTrackingDetailsViewController.h
//  CheckMate
//
//  Created by Rwithu Menon on 09/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CMUserTrackingDetailsViewController : UIViewController

@property (strong, nonatomic) PFUser *currentUser;

@end
