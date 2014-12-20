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
#import "NSAttributedString+Style.h"

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
    
    self.distLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.1f", [sum.total_dist floatValue]/1000.0f] font:[UIFont boldSystemFontOfSize:18] color:[UIColor blackColor] andUnit:@"km" font:[UIFont boldSystemFontOfSize:11] color:[UIColor blackColor]];
    self.speedLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.1f", [sum.max_speed floatValue]*3.6] font:[UIFont boldSystemFontOfSize:18] color:[UIColor blackColor] andUnit:@"km/h" font:[UIFont boldSystemFontOfSize:11] color:[UIColor blackColor]];
    self.duringLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.f", [sum.total_during floatValue]/60.0] font:[UIFont boldSystemFontOfSize:18] color:[UIColor blackColor] andUnit:@"min" font:[UIFont boldSystemFontOfSize:11] color:[UIColor blackColor]];
    self.trafficLightLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%ld", (long)[sum.traffic_light_jam_cnt integerValue]] font:[UIFont boldSystemFontOfSize:18] color:[UIColor blackColor] andUnit:@"处" font:[UIFont boldSystemFontOfSize:11] color:[UIColor blackColor]];
}

@end
