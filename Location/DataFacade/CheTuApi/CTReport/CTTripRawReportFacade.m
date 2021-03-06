//
//  CTTripRawReportFacade.m
//  TripMan
//
//  Created by taq on 3/6/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTTripRawReportFacade.h"

@implementation CTTripRawReportFacade

- (eRequestType)requestType{
    return eRequestTypePost;
}

- (NSString *)getPath
{
    NSDictionary * plistDict = [[NSBundle mainBundle] infoDictionary];
    NSString * path = [NSString stringWithFormat:@"trip/raw?tid=%@&version=%@", self.sum.trip_id, plistDict[@"CFBundleVersion"]];
    return path;
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonGzipType;
}

- (id)requestParam
{
    if (self.sum.trip_id && self.sum.start_date && self.sum.end_date) {
        GPSFMDBLogger * loggerDB = [GPSLogger sharedLogger].dbLogger;
        NSMutableArray * rawData = [NSMutableArray array];
        NSArray * logArr = [loggerDB selectLogFrom:self.sum.start_date toDate:self.sum.end_date offset:0 limit:0];
        for (GPSLogItem * item in logArr) {
            [rawData addObject:[item toArray]];
        }
        return rawData;
    }
    
    return nil;
}

- (id)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    return data;
}

@end
