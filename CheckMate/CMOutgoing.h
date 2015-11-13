//
//  CMOutgoing.h
//  CheckMate
//
//  Created by Rwithu Menon on 12/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CMOutgoing : NSObject

- (void)send:(NSString *)text withRecipients:(NSMutableArray *)recipients;

@end
