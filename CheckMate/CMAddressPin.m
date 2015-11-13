//
//  CMAddressPin.m
//  CheckMate
//
//  Created by Rwithu Menon on 11/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMAddressPin.h"

@implementation CMAddressPin

@synthesize coordinate;

- (NSString *)subtitle{
    return nil;
}

- (NSString *)title{
    return nil;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D) c{
    coordinate=c;
    return self;
}
@end
