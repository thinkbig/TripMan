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

//- (NSString *)getPath{
//    return @"%@?uid=someUserId";
//}

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
