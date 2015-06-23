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

- (NSString *)getPath
{
    NSMutableString * path = [NSMutableString stringWithString:@"parking/detail"];
    
    NSDictionary * plistDict = [[NSBundle mainBundle] infoDictionary];
    [path appendFormat:@"?version=%@", plistDict[@"CFBundleVersion"]];
    
    NSString * pid = self.aimRegion.parking_id;
    if (pid) {
        [path appendFormat:@"&pid=%@", pid];
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
    return [self.aimRegion toJsonDict];
}

- (id)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
