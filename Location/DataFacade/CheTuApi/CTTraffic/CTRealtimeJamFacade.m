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

// cache override

- (NSString*) keyByUrl:(NSString*)url resPath:(NSString*)path andParam:(NSDictionary*)param
{
    // 经纬度，一度大约为80~111km，所有取近似地点的时候，取小数点后3位，也就是百米作为误差
    return [NSString stringWithFormat:@"jamzone-%ld_%ld-%ld_%ld", lround(self.geoBound.minLon*1000), lround(self.geoBound.maxLon*1000), lround(self.geoBound.minLat*1000), lround(self.geoBound.maxLat*1000)];
}

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategyMemory;
}

- (NSTimeInterval) expiredDuring {
    return 60*3;
}

@end
