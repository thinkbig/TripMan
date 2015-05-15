//
//  CTTrafficFullFacade.m
//  TripMan
//
//  Created by taq on 3/20/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTTrafficFullFacade.h"
#import "CTRoute.h"
#import "GeoTransformer.h"

@implementation CTTrafficFullFacade

- (NSString *)getPath {
    return @"traffic/fulluser";
}

- (eRequestType)requestType {
    return eRequestTypeGet;
}

- (NSDictionary*)requestParam {
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:
                                  @{@"from": [NSString stringWithFormat:@"%f,%f", self.fromCoorBaidu.longitude, self.fromCoorBaidu.latitude],
                                    @"to": [NSString stringWithFormat:@"%f,%f", self.toCoorBaidu.longitude, self.toCoorBaidu.latitude]}];
    if (self.fromParkingId && self.toParkingId) {
        dict[@"fromId"] = self.fromParkingId;
        dict[@"toId"] = self.toParkingId;
    }
    return dict;
}

- (id)parseRespData:(id)data error:(NSError *__autoreleasing *)err {
    CTRoute * route = [[CTRoute alloc] initWithDictionary:data error:nil];
    return route;
}

#pragma mark - cache override

- (NSString*) keyByUrl:(NSString*)url resPath:(NSString*)path andParam:(NSDictionary*)param
{
    // 经纬度，一度大约为80~111km，所有取近似地点的时候，取小数点后3位，也就是百米作为误差
    return [NSString stringWithFormat:@"full-%ld_%ld-%ld_%ld", lround(self.fromCoorBaidu.latitude*1000), lround(self.fromCoorBaidu.longitude*1000), lround(self.toCoorBaidu.latitude*1000), lround(self.toCoorBaidu.longitude*1000)];
}

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategyMemory;
}

- (NSTimeInterval) expiredDuring {
    return 60*10;
}

@end
