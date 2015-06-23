//
//  GRoadSnapFacade.m
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GRoadSnapFacade.h"
#import "GeoTransformer.h"

@implementation GRoadSnapFacade

- (NSString *)getPath
{
    NSString * format = [super getPath];
    return [NSString stringWithFormat:format, @"snapToRoads"];
}

- (NSDictionary*)requestParam {
    NSString * seg = @"";
    NSMutableString * wayStr = [[NSMutableString alloc] init];
    for (id item in self.snapPath) {
        CLLocationCoordinate2D coor = [item coordinate];
        CLLocationCoordinate2D marsCoor = [GeoTransformer earth2Mars:coor];
        [wayStr appendFormat:@"%@%.5f,%.5f", seg, marsCoor.latitude, marsCoor.longitude];
        seg = @"|";
    }
    NSLog(@"@@@ show route = (%ld) %@", (unsigned long)self.snapPath.count, wayStr);
    return @{@"path": wayStr, @"interpolate": (self.interpolate ? @"true" : @"false")};
}

- (id)parseRespData:(NSDictionary *)dict error:(NSError **)err
{
    NSArray * snapPts = dict[@"snappedPoints"];
    NSMutableArray * snapModels = [NSMutableArray arrayWithCapacity:snapPts.count];
    for (NSDictionary * oneSnap in snapPts) {
        GSnapPtModel * model = [[GSnapPtModel alloc] initWithDictionary:oneSnap error:err];
        [snapModels addObject:model];
    }
    return snapModels;
}

@end
