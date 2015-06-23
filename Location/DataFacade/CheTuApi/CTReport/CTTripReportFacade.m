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

- (NSString *)getPath
{
    NSMutableString * path = [NSMutableString stringWithString:@"trip/detail"];
    
    NSDictionary * plistDict = [[NSBundle mainBundle] infoDictionary];
    [path appendFormat:@"?version=%@", plistDict[@"CFBundleVersion"]];
    
    NSString * tid = self.sum.trip_id;
    if (tid) {
        [path appendFormat:@"&tid=%@", tid];
    }
    if (self.force) {
        [path appendFormat:@"&force=1"];
    }
    return path;
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonGzipType;
}

- (NSDictionary*)requestParam
{
    return [self.sum toJsonDict];
}

- (id)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
