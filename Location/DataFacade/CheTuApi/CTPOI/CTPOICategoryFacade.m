//
//  CTPOICategoryFacade.m
//  TripMan
//
//  Created by taq on 12/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CTPOICategoryFacade.h"

@implementation CTPOICategoryFacade

- (NSString *)getPath
{
    NSString * format = [super getPath];
    NSString * basePath = [NSString stringWithFormat:format, @"poiCategory"];
    return basePath;
}

- (NSDictionary*)requestParam
{
    NSString * city = [BussinessDataProvider sharedInstance].currentCity;
    if (city) {
        return @{@"city": city};
    }
    return [super requestParam];
}

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategyFile;
}

- (eCallbackStrategy) callbackStrategy {
    return eCallBackCacheAndRequestNew;
}

- (id)parseRespData:(NSArray*)data error:(NSError **)err
{
    if ([data isKindOfClass:[NSArray class]]) {
        NSMutableArray * allList = [[NSMutableArray alloc] initWithCapacity:data.count];
        for (NSDictionary * oneItem in data) {
            POICategory * model = [[POICategory alloc] initWithDictionary:oneItem error:nil];
            [allList addObject:model];
        }
        return allList;
    }
    return nil;
}

- (NSArray*) defaultCategorys
{
    NSString * mockStr = @"[{\"poi_type\":1,\"disp_name\":\"我关注的地点\"},{\"poi_type\":2,\"disp_name\":\"美食\"},{\"poi_type\":3,\"disp_name\":\"购物\"},{\"poi_type\":4,\"disp_name\":\"加油站\"},{\"poi_type\":5,\"disp_name\":\"停车场\"}]";
    NSArray * mockArr = [CommonFacade fromJsonString:mockStr];
    return [self parseRespData:mockArr error:nil];
}

@end
