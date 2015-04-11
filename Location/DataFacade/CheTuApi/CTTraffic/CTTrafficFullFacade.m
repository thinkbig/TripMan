//
//  CTTrafficFullFacade.m
//  TripMan
//
//  Created by taq on 3/20/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTTrafficFullFacade.h"
#import "CTRoute.h"
#import "GeoTransformer.h"

@implementation CTTrafficFullFacade

- (NSString *)getPath {
    return @"traffic/fullbaidu";
}

- (eRequestType)requestType {
    return eRequestTypeGet;
}

- (NSDictionary*)requestParam {
    NSMutableDictionary * param = [[NSMutableDictionary alloc] initWithDictionary:@{@"from": [NSString stringWithFormat:@"%.5f,%.5f", self.fromCoorBaidu.longitude, self.fromCoorBaidu.latitude], @"to": [NSString stringWithFormat:@"%.5f,%.5f", self.toCoorBaidu.longitude, self.toCoorBaidu.latitude]}];
    
    if (self.wayPtsBaidu.count > 0) {
        NSString * seg = @"";
        NSMutableString * wayStr = [[NSMutableString alloc] init];
        for (NSDictionary * ptDict in self.wayPtsBaidu) {
            [wayStr appendFormat:@"%@%.5f,%.5f", seg, [ptDict[@"lon"] floatValue], [ptDict[@"lat"] floatValue]];
            seg = @"|";
        }
        param[@"waypoints"] = wayStr;
    }
    
    return param;
}

- (void) updateWithGpsWayPts:(NSArray*)waypts
{
    return;
    NSMutableArray * ptArr = [NSMutableArray array];
    for (CLLocation * loc in waypts) {
        CLLocationCoordinate2D bdCoor = [GeoTransformer earth2Baidu:loc.coordinate];
        [ptArr addObject:@{@"lat": @(bdCoor.latitude), @"lon": @(bdCoor.longitude)}];
    }
    self.wayPtsBaidu = ptArr;
}

- (id)parseRespData:(id)data error:(NSError *__autoreleasing *)err {
    CTRoute * route = [[CTRoute alloc] initWithDictionary:data error:nil];
    return route;
}

#pragma mark - cache override

- (NSString*) keyByUrl:(NSString*)url resPath:(NSString*)path andParam:(NSDictionary*)param
{
    // 经纬度，一度大约为80~111km，所有取近似地点的时候，取小数点后3位，也就是百米作为误差
    return [NSString stringWithFormat:@"%ld_full_%ld-%ld_%ld-%ld", lround(self.fromCoorBaidu.latitude*1000), lround(self.fromCoorBaidu.longitude*1000), lround(self.toCoorBaidu.latitude*1000), lround(self.toCoorBaidu.longitude*1000), (unsigned long)self.wayPtsBaidu.count];
}

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategyMemory;
}

- (NSTimeInterval) expiredDuring {
    return 60*5;
}

@end
