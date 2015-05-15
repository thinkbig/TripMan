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

- (NSString *)getPath
{
    NSMutableString * path = [NSMutableString stringWithString:@"trip/realtime"];
    
    NSString * sep = @"?";
    NSString * jam_id = self.reportModel.jam_id;
    if (jam_id) {
        [path appendFormat:@"%@jam_id=%@", sep, jam_id];
        sep = @"&";
    }
    if (self.ignore) {
        [path appendFormat:@"%@ignore=1", sep];
        sep = @"&";
    }
    return path;
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonGzipType;
}

- (NSDictionary*)requestParam
{
    return [self.reportModel toDictionary];
}

- (id)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
