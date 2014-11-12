//
//  Earth2Mars.h
//  Location
//
//  Created by taq on 9/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GeoTransformer : NSObject

+ (CLLocationCoordinate2D)earth2Mars:(CLLocationCoordinate2D)location;
+ (CLLocationCoordinate2D)earth2Baidu:(CLLocationCoordinate2D)location;

@end