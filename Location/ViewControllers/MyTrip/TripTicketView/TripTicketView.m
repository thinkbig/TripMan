//
//  TripTicketView.m
//  Location
//
//  Created by taq on 11/8/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripTicketView.h"

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
    static NSDateFormatter *sDateFormatter = nil;
    if (nil == sDateFormatter) {
        sDateFormatter = [[NSDateFormatter alloc] init];
        [sDateFormatter setDateFormat: @"HH:mm"];
        [sDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    
    self.fromPoi.text = [self safeText:sum.region_group.start_region.nearby_poi withDefault:@"未知地点"];
    self.fromStreet.text = [self safeText:sum.region_group.start_region.street withDefault:@"未知街道"];
    self.fromDate.text = sum.start_date ? [sDateFormatter stringFromDate:sum.start_date] : @"未知时间";
    
    if (sum.end_date) {
        self.toPoi.text = [self safeText:sum.region_group.end_region.nearby_poi withDefault:@"未知地点"];
        self.toStreet.text = [self safeText:sum.region_group.end_region.street withDefault:@"未知街道"];
        self.toDate.text = [sDateFormatter stringFromDate:sum.end_date];
    } else {
        self.toPoi.text = @"行驶中";
        self.toStreet.text = @"......";
        self.toDate.text = [sDateFormatter stringFromDate:[NSDate date]];
    }
    
    self.distLabel.text = [NSString stringWithFormat:@"里程: %@", sum.total_dist];
    self.speedLabel.text = [NSString stringWithFormat:@"最高速度: %@", sum.max_speed];
    self.duringLabel.text = [NSString stringWithFormat:@"耗时: %@", sum.total_during];
    self.jamDuring.text = [NSString stringWithFormat:@"缓行时间: %@", sum.traffic_jam_during];
}

@end
