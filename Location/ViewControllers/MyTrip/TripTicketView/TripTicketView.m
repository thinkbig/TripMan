//
//  TripTicketView.m
//  Location
//
//  Created by taq on 11/8/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripTicketView.h"
#import "ParkingRegion.h"
#import "RegionGroup.h"

@implementation TripTicketView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (NSString*) safeText:(NSString*)str withDefault:(NSString*)defaultStr
{
    return str.length > 0 ? str : defaultStr;
}

- (void) updateWithTripSummary:(TripSummary*)sum
{
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    
    self.fromPoi.text = [self safeText:sum.region_group.start_region.nearby_poi withDefault:@"未知"];
    self.fromStreet.text = [self safeText:sum.region_group.start_region.street withDefault:@"未知街道"];
    self.fromDate.text = sum.start_date ? [formatter stringFromDate:sum.start_date] : @"未知";
    
    if (sum.end_date) {
        self.toPoi.text = [self safeText:sum.region_group.end_region.nearby_poi withDefault:@"未知"];
        self.toStreet.text = [self safeText:sum.region_group.end_region.street withDefault:@"未知街道"];
        self.toDate.text = [formatter stringFromDate:sum.end_date];
    } else if (sum) {
        self.toPoi.text = @"行驶中";
        self.toDate.text = [formatter stringFromDate:[NSDate date]];
    } else {
        self.toPoi.text = @"未知";
        self.toDate.text = @"00:00";
    }
    
    self.distLabel.text = [NSString stringWithFormat:@"%.1fkm", [sum.total_dist floatValue]/1000.0f];
    self.speedLabel.text = [NSString stringWithFormat:@"%.1fkm/h", [sum.max_speed floatValue]*3.6];
    self.duringLabel.text = [NSString stringWithFormat:@"%.fmin", [sum.total_during floatValue]/60.0];
    self.trafficLightLabel.text = sum.traffic_light_jam_cnt ? [NSString stringWithFormat:@"%@处", sum.traffic_light_jam_cnt] : @"未知";
}

@end
