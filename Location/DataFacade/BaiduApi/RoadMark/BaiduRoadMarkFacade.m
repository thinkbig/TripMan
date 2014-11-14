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

@end
