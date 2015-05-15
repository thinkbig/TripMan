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
    
    NSString * sep = @"?";
    NSString * pid = self.aimRegion.parking_id;
    if (pid) {
        [path appendFormat:@"%@pid=%@", sep, pid];
        sep = @"&";
    }
    if (self.force) {
        [path appendFormat:@"%@force=1", sep];
        sep = @"&";
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
