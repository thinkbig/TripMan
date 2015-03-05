//
//  BaiduRoadMarkFacade.m
//  TripMan
//
//  Created by taq on 11/13/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaiduRoadMarkFacade.h"

@implementation BaiduRoadMarkFacade

- (NSString*)coor2String:(CLLocationCoordinate2D)coor
{
    return [NSString stringWithFormat:@"%f,%f", coor.longitude, coor.latitude];
}

- (NSString *)getPath
{
    NSString * format = [super getPath];
    return [NSString stringWithFormat:format, @"viaPath"];
}

- (NSDictionary*)requestParam {
    return @{@"origin":[self coor2String:self.fromCoor], @"destination":[self coor2String:self.toCoor], @"coord_type":@"wgs84"};
}

- (NSArray*) processingOrigResult:(NSDictionary*)origResult error:(NSError **)err
{
    if ([origResult isKindOfClass:[NSDictionary class]] && (origResult[@"error"] == 0 || [@"success" isEqualToString:origResult[@"status"]])) {
        return origResult[@"results"];
    } else {
        *err = ERR_MAKE(eBussinessError, @"获取路标异常");
    }
    return nil;
}

- (id)parseRespData:(NSDictionary *)dict error:(NSError **)err
{
    return [[BaiduMarkModel alloc] initWithDictionary:dict error:err];
}

#pragma mark - cache override

- (NSString*) keyByUrl:(NSString*)url resPath:(NSString*)path andParam:(NSDictionary*)param
{
    // 经纬度，一度大约为80~111km，所有取近似地点的时候，取小数点后3位，也就是百米作为误差
    return [NSString stringWithFormat:@"rm-%ld_%ld-%ld_%ld", lround(self.fromCoor.latitude*1000), lround(self.fromCoor.longitude*1000), lround(self.toCoor.latitude*1000), lround(self.toCoor.longitude*1000)];
}

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategySqlite;
}

@end
