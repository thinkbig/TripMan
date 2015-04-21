//
//  CTTimePredictFacade.m
//  TripMan
//
//  Created by taq on 4/19/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTTimePredictFacade.h"

@implementation CTTimePredictFacade

- (NSString *)getPath {
    return @"traffic/predictuser";
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
    NSString * udid = [[GToolUtil sharedInstance] deviceId];
    NSString * uid = [[GToolUtil sharedInstance] userId];
    if (uid) {
        dict[@"uid"] = uid;
    }
    if (udid) {
        dict[@"udid"] = udid;
    }
    return dict;
}

- (id)parseRespData:(id)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
