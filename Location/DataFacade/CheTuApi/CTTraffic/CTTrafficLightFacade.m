//
//  CTTrafficLightFacade.m
//  TripMan
//
//  Created by taq on 3/16/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTTrafficLightFacade.h"
#import "CTBaseLocation.h"

@implementation CTTrafficLightFacade

- (NSString *)getPath {
    return @"traffic/trafficlight";
}

- (eRequestType)requestType {
    return eRequestTypePost;
}

- (eSerializationType)requestSerializationType {
    return eSerializationJsonType;
}

- (NSDictionary*)requestParam {
    return @{@"from": [self coor2String:self.fromCoorBD],
             @"to": [self coor2String:self.toCoorBD],
             @"in_coor": @"baidu"};
}

- (NSArray*)parseRespData:(NSDictionary*)data error:(NSError *__autoreleasing *)err {
    NSArray * lights = data[@"trafficlights"];
    NSMutableArray * lightModels = [NSMutableArray arrayWithCapacity:lights.count];
    for (NSDictionary * light in lights) {
        CTBaseLocation * loc = [[CTBaseLocation alloc] initWithDictionary:light error:nil];
        [lightModels addObject:loc];
    }
    return lightModels;
}

#pragma mark - cache override

- (NSString*) keyByUrl:(NSString*)url resPath:(NSString*)path andParam:(NSDictionary*)param
{
    // 经纬度，一度大约为80~111km，所有取近似地点的时候，取小数点后3位，也就是百米作为误差
    return [NSString stringWithFormat:@"tl-%ld_%ld-%ld_%ld", lround(self.fromCoorBD.latitude*1000), lround(self.fromCoorBD.longitude*1000), lround(self.toCoorBD.latitude*1000), lround(self.toCoorBD.longitude*1000)];
}

- (eCacheStrategy) cacheStrategy {
    return eCacheStrategySqlite;
}

@end
