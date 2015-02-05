//
//  TripSummary+Fetcher.m
//  TripMan
//
//  Created by taq on 2/4/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TripSummary+Fetcher.h"

@implementation TripSummary (Fetcher)

- (eTrafficStatus) trafficStatus
{
    eTrafficStatus status = eTrafficGreen;
    NSInteger heavyJam = [self.traffic_heavy_jam_cnt integerValue];
    if (heavyJam > 0) {
        NSTimeInterval jamWithoutLight = [self.traffic_jam_during floatValue] - [self.traffic_light_jam_cnt integerValue]*30;
        if (jamWithoutLight/heavyJam > TRAFFIC_YELLOW_THRESHOLD) {
            status = eTrafficYellow;
            if ((jamWithoutLight-TRAFFIC_YELLOW_THRESHOLD*(heavyJam-1)) > TRAFFIC_RED_THRESHOLD) {
                status = eTrafficRed;
            }
        }
    }
    return status;
}

@end
