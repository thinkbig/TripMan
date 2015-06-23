//
//  CTTestFacade.m
//  TripMan
//
//  Created by taq on 5/5/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTTestFacade.h"
#import "CTRoute.h"

@implementation CTTestFacade

// http://121.43.230.8:8080/api/traffic/roadsvisualization.s?lonFromTo=120.50,120.70&latFromTo=31.2,31.6
- (NSString *)baseUrl {
    return @"http://121.43.230.8:8080/api/";
}

- (NSString *)getPath {
    return @"traffic/roadsvisualization.s";
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
    NSMutableArray * stepModels = [NSMutableArray arrayWithCapacity:zones.count];
    for (NSDictionary * zone in zones) {
        CTJam * step = [[CTJam alloc] initWithDictionary:zone error:nil];
        [stepModels addObject:step];
    }
    return stepModels;
}

@end
