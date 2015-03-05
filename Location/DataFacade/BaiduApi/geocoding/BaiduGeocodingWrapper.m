//
//  BaiduGeocodingWrapper.m
//  Location
//
//  Created by taq on 11/3/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaiduGeocodingWrapper.h"

@interface BaiduGeocodingWrapper ()

@property (nonatomic, strong) BMKGeoCodeSearch *        geocodesearch;

@end

@implementation BaiduGeocodingWrapper

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

- (void)realSendRequest
{
    if (self.city.length == 0 || self.address.length == 0) {
        if (self.failureBlock) {
            self.failureBlock(ERR_MAKE(eInvalidInputError, @"查询城市或地址为空"));
        }
        return;
    }
    
    BMKGeoCodeSearchOption *geocodeSearchOption = [BMKGeoCodeSearchOption new];
    geocodeSearchOption.city= self.city;
    geocodeSearchOption.address = self.address;
    if ([self.geocodesearch geoCode:geocodeSearchOption] && self.failureBlock) {
        self.failureBlock(ERR_MAKE(eInvalidInputError, @"查询失败"));
    }
}


- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == 0) {
        if (self.successBlock) {
            self.successBlock(result);
        }
    } else if (self.failureBlock) {
        self.failureBlock(ERR_MAKE(error, @"查询经纬度失败"));
    }
}

@end
