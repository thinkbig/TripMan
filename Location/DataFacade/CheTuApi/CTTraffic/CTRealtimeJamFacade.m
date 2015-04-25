//
//  CTRealtimeJamFacade.m
//  TripMan
//
//  Created by taq on 4/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTRealtimeJamFacade.h"
#import "JamZone.h"

@implementation CTRealtimeJamFacade

- (NSString *)getPath {
    return @"traffic/jamszone";
}

- (eRequestType)requestType {
    return eRequestTypeGet;
}

- (NSDictionary*)requestParam
{
    return @{@"lonFromTo": [NSString stringWithFormat:@"%.5f,%.5f", self.geoBound.minLon, self.geoBound.maxLon],
             @"latFromTo": [NSString stringWithFormat:@"%.5f,%.5f", self.geoBound.minLat, self.geoBound.maxLat]};
}

- (NSArray*)parseRespData:(NSArray*)zones error:(NSError *__autoreleasing *)err {
    NSMutableArray * zoneModels = [NSMutableArray arrayWithCapacity:zones.count];
    for (NSDictionary * zone in zones) {
        JamZone * loc = [[JamZone alloc] initWithDictionary:zone error:nil];
        [zoneModels addObject:loc];
    }
    return zoneModels;
}

@end
