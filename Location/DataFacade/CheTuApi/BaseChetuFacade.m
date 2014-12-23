//
//  BaseChetuFacade.m
//  TripMan
//
//  Created by taq on 12/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaseChetuFacade.h"

@implementation BaseChetuFacade

- (eRequestType)requestType{
    return eRequestTypeGet;
}

- (NSString *)baseUrl {
    return @"http://myhost/";
}

- (NSString *)getPath{
    return @"%@?uid=someUserId";
}

- (NSArray*) processingOrigResult:(NSDictionary*)origResult error:(NSError **)err
{
    NSInteger code = [origResult[@"code"] integerValue];
    if ([origResult isKindOfClass:[NSDictionary class]] && (code == 0)) {
        return origResult[@"data"];
    } else if (code != 0) {
        *err = ERR_MAKE(code, origResult[@"msg"]);
    } else {
        *err = ERR_MAKE(eBussinessError, @"数据异常");
    }
    return nil;
}

@end
