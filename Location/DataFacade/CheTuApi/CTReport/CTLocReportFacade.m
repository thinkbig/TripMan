//
//  CTLocReportFacade.m
//  TripMan
//
//  Created by taq on 3/5/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTLocReportFacade.h"

@implementation CTLocReportFacade

- (eRequestType)requestType{
    return eRequestTypePost;
}

- (NSString *)getPath {
    NSString * udid = [GToolUtil deviceId];
    NSString * uid = [GToolUtil userId];
    NSString * pid = self.aimRegion.parking_id;
    NSMutableString * path = [NSMutableString stringWithFormat:@"parking/detail?udid=%@", udid];
    if (uid) {
        [path appendFormat:@"&uid=%@", uid];
    }
    if (pid) {
        [path appendFormat:@"&pid=%@", pid];
    }
    return path;
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonGzipType;
}

- (NSDictionary*)requestParam
{
    return [self.aimRegion toJsonDict];
}

- (id)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
