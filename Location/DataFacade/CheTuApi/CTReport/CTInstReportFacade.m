//
//  CTInstReportFacade.m
//  TripMan
//
//  Created by taq on 4/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTInstReportFacade.h"

@implementation CTInstReportFacade

- (eRequestType)requestType{
    return eRequestTypePost;
}

- (NSString *)getPath {
    NSString * udid = [[GToolUtil sharedInstance] deviceId];
    NSString * uid = [[GToolUtil sharedInstance] userId];
    NSString * jam_id = self.reportModel.jam_id;
    NSMutableString * path = [NSMutableString stringWithFormat:@"trip/realtime?udid=%@", udid];
    if (uid) {
        [path appendFormat:@"&uid=%@", uid];
    }
    if (jam_id) {
        [path appendFormat:@"&jam_id=%@", jam_id];
    }
    return path;
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonType;
}

- (NSDictionary*)requestParam
{
    return [self.reportModel toDictionary];
}

- (id)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
