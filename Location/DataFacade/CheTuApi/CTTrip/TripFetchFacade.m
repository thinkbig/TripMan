//
//  TripFetchFacade.m
//  TripMan
//
//  Created by taq on 6/13/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "TripFetchFacade.h"

@implementation TripFetchFacade

- (NSString *)getPath {
    return @"trip/trip";
}

- (eRequestType)requestType {
    return eRequestTypeGet;
}

- (NSDictionary*)requestParam {
    return @{@"tid": self.tripId};
}

- (id)parseRespData:(id)data error:(NSError *__autoreleasing *)err {
    CTTrip * route = [[CTTrip alloc] initWithDictionary:data error:nil];
    return route;
}

#pragma mark - cache override

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategySqlite;
}

- (NSTimeInterval) expiredDuring {
    return 60*60*24*30;
}

@end
