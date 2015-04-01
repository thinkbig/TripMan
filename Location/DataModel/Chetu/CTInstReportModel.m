//
//  CTInstReportModel.m
//  TripMan
//
//  Created by taq on 4/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CTInstReportModel.h"

@implementation CTInstReportModel

- (void) updateWithStartItem:(GPSLogItem*)item
{
    self.st_date = @([item.timestamp timeIntervalSince1970]);
    self.st_lat = item.latitude;
    self.st_lon = item.longitude;
}

- (void) updateWithUserLocation:(CLLocationCoordinate2D)locCoor
{
    self.user_lat = @(locCoor.latitude);
    self.user_lon = @(locCoor.longitude);
}

- (CLLocationCoordinate2D) userCoordinate
{
    return CLLocationCoordinate2DMake([self.user_lat doubleValue], [self.user_lon doubleValue]);
}

- (void) updateWithEndItem:(GPSLogItem*)item
{
    self.ed_date = @([item.timestamp timeIntervalSince1970]);
    self.ed_lat = item.latitude;
    self.ed_lon = item.longitude;
}

- (BOOL)isEqual:(CTInstReportModel*)object
{
    return [self.st_date isEqualToNumber:object.st_date] || [self.jam_id isEqualToString:object.jam_id];
}

@end
