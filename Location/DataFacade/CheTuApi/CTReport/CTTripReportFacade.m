//
//  CTTripReportFacade.m
//  TripMan
//
//  Created by taq on 3/6/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTTripReportFacade.h"

@implementation CTTripReportFacade

- (eRequestType)requestType{
    return eRequestTypePost;
}

- (NSString *)getPath {
    NSString * udid = [GToolUtil deviceId];
    NSString * uid = [GToolUtil userId];
    NSString * tid = self.sum.trip_id;
    NSMutableString * path = [NSMutableString stringWithFormat:@"trip/detail?udid=%@", udid];
    if (uid) {
        [path appendFormat:@"&uid=%@", uid];
    }
    if (tid) {
        [path appendFormat:@"&tid=%@", tid];
    }
    return path;
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonType;
}

- (NSDictionary*)requestParam
{
    return [self.sum toJsonDict];
}

- (id)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
