//
//  BaseChetuFacade.m
//  TripMan
//
//  Created by taq on 12/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaseChetuFacade.h"

@implementation BaseChetuFacade

- (NSString*)coor2String:(CLLocationCoordinate2D)coor
{
    return [NSString stringWithFormat:@"%f,%f", coor.longitude, coor.latitude];
}

- (eRequestType)requestType{
    return eRequestTypeGet;
}

- (NSString *)baseUrl {
    return kChetuBaseUrl;
}

- (NSDictionary*)requestHeader {
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    NSString * udid = [[GToolUtil sharedInstance] deviceId];
    NSString * uid = [[GToolUtil sharedInstance] userId];
    if (uid) {
        dict[@"uid"] = uid;
    }
    if (udid) {
        dict[@"udid"] = udid;
    }
    return dict;
}

- (NSMutableString *)ctPathWithResPath:(NSString*)resPath
{
    NSMutableString * path = [NSMutableString stringWithString:resPath];
    if (![resPath hasSuffix:@"?"] && ![resPath hasSuffix:@"&"]) {
        NSString * sep = @"?";
        if ([resPath containsString:@"?"]) {
            sep = @"&";
        }
        [path appendString:sep];
    }
    
    NSString * udid = [[GToolUtil sharedInstance] deviceId];
    [path appendFormat:@"udid=%@", udid];
    
    NSString * uid = [[GToolUtil sharedInstance] userId];
    if (uid) {
        [path appendFormat:@"&uid=%@", uid];
    }
    
    return path;
}

- (id) processingOrigResult:(NSDictionary*)origResult error:(NSError **)err
{
    NSInteger code = [origResult[@"code"] integerValue];
    if ([origResult isKindOfClass:[NSDictionary class]] && (code == 0)) {
        return origResult[@"data"];
    } else if (code != 0) {
        *err = ERR_MAKE(code, origResult[@"msg"]);
    } else {
        *err = ERR_MAKE(eBussinessError, @"数据异常");
    }
    return origResult;
}

@end
