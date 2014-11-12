//
//  BaiduWeatherFacade.m
//  Location
//
//  Created by taq on 11/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "BaiduWeatherFacade.h"

static NSDateFormatter *sDateFormatter = nil;

@implementation BaiduWeatherFacade

+ (NSString*)_keyForCaching:(NSDate*)date
{
    if (nil == sDateFormatter) {
        sDateFormatter = [[NSDateFormatter alloc] init];
        [sDateFormatter setDateFormat: @"kWeatherByDate_yyyy-MM-dd"];
        [sDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return [sDateFormatter stringFromDate:date];
}

- (NSDictionary*)requestParam {
    if (self.city.length > 0) {
        return @{@"location":self.city};
    }
    return nil;
}

- (NSArray*) processingOrigResult:(NSDictionary*)origResult error:(NSError **)err
{
    if ([origResult isKindOfClass:[NSDictionary class]] && (origResult[@"error"] == 0 || [@"success" isEqualToString:origResult[@"status"]])) {
        return origResult[@"results"];
    } else {
        *err = ERR_MAKE(eBussinessError, @"天气服务异常");
    }
    return nil;
}

- (id)parseRespData:(NSArray *)arr error:(NSError **)err
{
    if (arr.count > 0) {
        return [[BaiduWeatherModel alloc] initWithDictionary:arr[0] error:err];
    }
    return nil;
}

@end
