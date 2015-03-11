//
//  CTGzipTestFacade.m
//  TripMan
//
//  Created by taq on 3/11/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTGzipTestFacade.h"
#import "TripSummary+Fetcher.h"

@implementation CTGzipTestFacade

- (eRequestType)requestType{
    return eRequestTypePost;
}

- (NSString *)getPath {
    return @"welcome/gzip";
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonGzipType;
}

- (id)requestParam
{
    TripSummary * sum = [[[AnaDbManager deviceDb] tripsReadyToReport:YES] lastObject];
    
    GPSFMDBLogger * loggerDB = [GPSLogger sharedLogger].dbLogger;
    NSMutableArray * rawData = [NSMutableArray array];
    NSArray * logArr = [loggerDB selectLogFrom:sum.start_date toDate:sum.end_date offset:0 limit:0];
    for (GPSLogItem * item in logArr) {
        [rawData addObject:[item toArray]];
    }

    NSString * str = [CommonFacade toJsonString:(NSDictionary*)rawData prettyPrint:NO];
    NSLog(@"len = %ld", str.length);
    return rawData;
    
    return @{@"aa": @"dd", @"bb" : @(3.2), @"arr" : @[@"asdf", @"acdcd", @(12)]};
}

- (id)parseRespData:(id)data error:(NSError *__autoreleasing *)err {
    NSLog(@"return data = %@", data);
    return data;
}

@end
