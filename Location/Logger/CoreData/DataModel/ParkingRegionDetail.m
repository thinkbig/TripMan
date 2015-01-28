//
//  ParkingRegionDetail.m
//  Location
//
//  Created by taq on 11/5/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "ParkingRegionDetail.h"

@implementation ParkingRegionDetail

- (void) copyInfoFromAnother:(ParkingRegionDetail*)detail
{
    self.region = detail.region;
    self.coreDataItem.parking_id = detail.coreDataItem.parking_id;
    self.coreDataItem.addi_data = detail.coreDataItem.addi_data;
    self.coreDataItem.addi_info = detail.coreDataItem.addi_info;
    self.coreDataItem.center_lat = detail.coreDataItem.center_lat;
    self.coreDataItem.center_lon = detail.coreDataItem.center_lon;
    self.coreDataItem.user_mark = detail.coreDataItem.user_mark;
    
    if (detail.coreDataItem.address) {
        self.coreDataItem.address = detail.coreDataItem.address;
        self.coreDataItem.city = detail.coreDataItem.city;
        self.coreDataItem.district = detail.coreDataItem.district;
        self.coreDataItem.nearby_poi = detail.coreDataItem.nearby_poi;
        self.coreDataItem.province = detail.coreDataItem.province;
        self.coreDataItem.rate = detail.coreDataItem.rate;
        self.coreDataItem.street = detail.coreDataItem.street;
        self.coreDataItem.street_num = detail.coreDataItem.street_num;
    }
}

@end
