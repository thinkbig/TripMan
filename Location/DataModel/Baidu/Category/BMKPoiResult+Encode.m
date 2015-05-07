//
//  BMKPoiResult+Encode.m
//  TripMan
//
//  Created by taq on 5/7/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMKPoiResult+Encode.h"
#import "BMKPoiInfo+Encode.h"
#import "BMKCityListInfo+Encode.h"

@implementation BMKPoiResult (Encode)

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        self.totalPoiNum = [decoder decodeIntForKey:@"totalPoiNum"];
        self.currPoiNum = [decoder decodeIntForKey:@"currPoiNum"];
        self.pageNum = [decoder decodeIntForKey:@"pageNum"];
        self.pageIndex = [decoder decodeIntForKey:@"pageIndex"];
        self.poiInfoList = [decoder decodeObjectForKey:@"poiInfoList"];
        self.cityList = [decoder decodeObjectForKey:@"cityList"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:_totalPoiNum forKey:@"totalPoiNum"];
    [encoder encodeInt:_currPoiNum forKey:@"currPoiNum"];
    [encoder encodeInt:_pageNum forKey:@"pageNum"];
    [encoder encodeInt:_pageIndex forKey:@"pageIndex"];
    
    [encoder encodeObject:_poiInfoList forKey:@"poiInfoList"];
    [encoder encodeObject:_cityList forKey:@"cityList"];
}

- (id)copyWithZone:(NSZone *)zone
{
    BMKPoiResult *entry = [[[self class] allocWithZone:zone] init];
    entry.totalPoiNum = _totalPoiNum;
    entry.currPoiNum = _currPoiNum;
    entry.pageNum = _pageNum;
    entry.pageIndex = _pageIndex;
    entry.poiInfoList = [_poiInfoList copy];
    entry.cityList = [_cityList copy];
    return entry;
}

@end
