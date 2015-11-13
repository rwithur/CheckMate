//
//  CMIncoming.h
//  CheckMate
//
//  Created by Rwithu Menon on 12/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JSQMessages.h"


@interface CMIncoming : NSObject

- (JSQMessage *)create:(NSDictionary *)item;

@end
