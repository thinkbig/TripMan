//
//  BaiduReverseGeocodingWrapper.m
//  Location
//
//  Created by taq on 11/6/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaiduReverseGeocodingWrapper.h"

@interface BaiduReverseGeocodingWrapper ()

@property (nonatomic, strong) BMKGeoCodeSearch *        geocodesearch;

@end

@implementation BaiduReverseGeocodingWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        self.geocodesearch = [[BMKGeoCodeSearch alloc] init];
        self.geocodesearch.delegate = self;
    }
    return self;
}

- (void)dealloc {
    self.geocodesearch.delegate = nil;
}

- (NSString*) keyForRequest
{
    return [NSString stringWithFormat:@"bd_reverse_geocode_%ld-%ld", lround(self.coordinate.latitude*100000), lround(self.coordinate.longitude*100000)];
}

- (id)cachedResult
{
    return [[TSCache sharedInst] sqliteCacheForKey:[self keyForRequest]];
}

- (void)realSendRequest
{
    if (!CLLocationCoordinate2DIsValid(self.coordinate)) {
        if (self.failureBlock) {
            self.failureBlock(ERR_MAKE(eInvalidInputError, @"无效的经纬度"));
        }
        return;
    }
    
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
    reverseGeocodeSearchOption.reverseGeoPoint = self.coordinate;
    if (![_geocodesearch reverseGeoCode:reverseGeocodeSearchOption]) {
        if (self.failureBlock) {
            self.failureBlock(ERR_MAKE(eInvalidInputError, @"查询失败"));
        }
    } else {
        [[BussinessDataProvider sharedInstance].fuckBaidu addObject:self];
    }
}


-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == 0) {
        [[TSCache sharedInst] setSqlitCache:result forKey:[self keyForRequest]];
        if (self.successBlock) {
            self.successBlock(result);
        }
    } else if (self.failureBlock) {
        self.failureBlock(ERR_MAKE(error, @"查询地理位置名称失败"));
    }
    [[BussinessDataProvider sharedInstance].fuckBaidu removeObject:self];
}

@end
