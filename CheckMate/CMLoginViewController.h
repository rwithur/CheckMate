//
//  CMLoginViewController.h
//  CheckMate
//
//  Created by Rwithu Menon on 02/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^compBlock)(BOOL success);

@interface CMLoginViewController : UIViewController

- (void) familyLimitWithSecret:(NSString *)secret ExceededWithCompletionBlock: (compBlock) block;
@end
