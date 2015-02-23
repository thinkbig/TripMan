//
//  CTTrafficAbstractFacade.m
//  TripMan
//
//  Created by taq on 2/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTTrafficAbstractFacade.h"

@implementation CTTrafficAbstractFacade

- (NSString *)getPath {
    return [NSString stringWithFormat:@"traffic/abstract?from=%f,%f&to=%f,%f", self.fromCoorBaidu.longitude, self.fromCoorBaidu.latitude, self.toCoorBaidu.longitude, self.toCoorBaidu.latitude];
}

- (eRequestType)requestType {
    return eRequestTypeGet;
}

//- (NSDictionary *)requestParam {
//    return @{@"from": [NSString stringWithFormat:@"%f,%f", self.fromCoorBaidu.longitude, self.fromCoorBaidu.latitude],
//             @"to": [NSString stringWithFormat:@"%f,%f", self.toCoorBaidu.longitude, self.toCoorBaidu.latitude]};
//}

- (id)parseRespData:(id)data error:(NSError *__autoreleasing *)err {
    return data;
}

#pragma mark - cache override

- (NSString*) keyByUrl:(NSString*)url resPath:(NSString*)path andParam:(NSDictionary*)param
{
    // 经纬度，一度大约为80~111km，所有取近似地点的时候，取小数点后3位，也就是百米作为误差
    return [NSString stringWithFormat:@"%ld_%ld-%ld_%ld", lround(self.fromCoorBaidu.latitude*1000), lround(self.fromCoorBaidu.longitude*1000), lround(self.toCoorBaidu.latitude*1000), lround(self.toCoorBaidu.longitude*1000)];
}

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategyMemory;
}

- (NSTimeInterval) expiredDuring {
    return 60*3;
}

@end
