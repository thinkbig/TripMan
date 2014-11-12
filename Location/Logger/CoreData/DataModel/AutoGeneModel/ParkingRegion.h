//
//  ParkingRegion.h
//  Location
//
//  Created by taq on 11/7/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ParkingRegion : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * center_lat;
@property (nonatomic, retain) NSNumber * center_lon;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * describe;
@property (nonatomic, retain) NSString * district;
@property (nonatomic, retain) NSNumber * is_analyzed;
@property (nonatomic, retain) NSString * nearby_poi;
@property (nonatomic, retain) NSString * province;
@property (nonatomic, retain) NSNumber * rate;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * street_num;
@property (nonatomic, retain) NSString * user_mark;
@property (nonatomic, retain) NSNumber * is_temp;

@end
