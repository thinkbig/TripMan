//
//  TrafficInfo.h
//  Location
//
//  Created by taq on 11/7/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TrafficInfo : NSManagedObject

@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSNumber * traffic_avg_speed;
@property (nonatomic, retain) NSNumber * traffic_jam_dist;
@property (nonatomic, retain) NSNumber * traffic_jam_during;

@end
