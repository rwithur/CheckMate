//
//  CMAddressPin.h
//  CheckMate
//
//  Created by Rwithu Menon on 11/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface CMAddressPin : NSObject <MKAnnotation> {

CLLocationCoordinate2D coordinate;

}
-(id)initWithCoordinate:(CLLocationCoordinate2D) c;

@end
