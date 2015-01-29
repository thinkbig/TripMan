//
//  ParkingRegion+Fetcher.m
//  TripMan
//
//  Created by taq on 1/29/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "ParkingRegion+Fetcher.h"

@implementation ParkingRegion (Fetcher)

- (NSString*) nameWithDefault:(NSString*)defaultName {
    if (self.user_mark.length > 0) {
        return self.user_mark;
    } else if (self.nearby_poi.length > 0) {
        return self.nearby_poi;
    }
    return defaultName;
}

@end
