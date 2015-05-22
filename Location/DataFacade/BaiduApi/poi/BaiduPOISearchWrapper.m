//
//  BaiduPOISearchWrapper.m
//  Location
//
//  Created by taq on 11/3/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaiduPOISearchWrapper.h"

@interface BaiduPOISearchWrapper ()

@property (nonatomic, strong) BMKPoiSearch *        poiSearch;

@end

@implementation BaiduPOISearchWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        self.poiSearch = [[BMKPoiSearch alloc] init];
        self.poiSearch.delegate = self;
    }
    return self;
}

- (void)dealloc {
    self.poiSearch.delegate = nil;
}

- (void)realSendRequest
{
    if (self.city.length == 0 || self.searchName.length == 0) {
        if (self.failureBlock) {
            self.failureBlock(ERR_MAKE(eInvalidInputError, @"查询城市或地址为空"));
        }
        return;
    }
    
    BMKCitySearchOption *option = [[BMKCitySearchOption alloc]init];
    option.city = self.city;
    option.pageCapacity = 10;
    option.keyword = self.searchName;
    if (![self.poiSearch poiSearchInCity:option] && self.failureBlock) {
        self.failureBlock(ERR_MAKE(eInvalidInputError, @"查询失败，请稍后再试"));
    }
}

- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResult errorCode:(BMKSearchErrorCode)errorCode
{
    if (errorCode == 0) {
        [[TSCache sharedInst] setSqlitCache:poiResult forKey:[self keyForRequest] expiresIn:60*60*24*30];
        if (self.successBlock) {
            self.successBlock(poiResult);
        }
    } else if (self.failureBlock) {
        self.failureBlock(ERR_MAKE(errorCode, @"查询失败，请稍后再试"));
    }
}

- (NSString*) keyForRequest
{
    return [NSString stringWithFormat:@"poi-%@_%@", self.city, self.searchName];
}

- (id)cachedResult
{
    return [[TSCache sharedInst] sqliteCacheForKey:[self keyForRequest]];
}

@end
