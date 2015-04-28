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
#import "ParkingRegion+Fetcher.h"
#import "TripSummary+Fetcher.h"
#import "BaiduReverseGeocodingWrapper.h"

@interface TripTicketView ()

@property (nonatomic, strong) TripSummary * sum;

@end

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
    self.sum = sum;
    
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    
    self.fromPoi.text = [sum.region_group.start_region nameWithDefault:@"未知"];
    self.fromStreet.text = [self safeText:sum.region_group.start_region.street withDefault:@"未知街道"];
    self.fromDate.text = sum.start_date ? [formatter stringFromDate:sum.start_date] : @"未知";
    
    if (sum.end_date) {
        self.toPoi.text = [sum.region_group.end_region nameWithDefault:@"未知"];
        self.toStreet.text = [self safeText:sum.region_group.end_region.street withDefault:@"未知街道"];
        self.toDate.text = [formatter stringFromDate:sum.end_date];
    } else if (sum) {
        CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
        ParkingRegionDetail * endLoc = [[AnaDbManager sharedInst] parkingDetailForCoordinate:curLoc.coordinate minDist:500];
        if ([endLoc.coreDataItem.is_analyzed boolValue]) {
            self.toPoi.text = [endLoc.coreDataItem nameWithDefault:@"当前位置"];
            self.toStreet.text = @"可能在行驶中";
        } else {
            self.toPoi.text = @"当前位置";
            self.toStreet.text = @"可能在行驶中";
            BaiduReverseGeocodingWrapper * wrapper = [BaiduReverseGeocodingWrapper new];
            wrapper.coordinate = [GeoTransformer earth2Baidu:curLoc.coordinate];
            [wrapper requestWithSuccess:^(BMKReverseGeoCodeResult* result) {
                if (sum == self.sum) {
                    self.toPoi.text = @"当前位置";
                    self.toStreet.text = result.addressDetail.streetName;
                }
            } failure:nil];
        }
        self.toDate.text = [formatter stringFromDate:[NSDate date]];
    } else {
        self.toPoi.text = @"未知";
        self.toStreet.text = nil;
        self.toDate.text = @"00:00";
    }
    
    self.distLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.1f", [sum.total_dist floatValue]/1000.0f] font:[self.distLabel.font fontWithSize:17] color:self.distLabel.textColor andUnit:@"km" font:[self.distLabel.font fontWithSize:14] color:self.distLabel.textColor];
    self.speedLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.1f", [sum.max_speed floatValue]*3.6] font:[self.speedLabel.font fontWithSize:17] color:self.speedLabel.textColor andUnit:@"km/h" font:[self.speedLabel.font fontWithSize:14] color:self.speedLabel.textColor];
    self.duringLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%.f", [sum.total_during floatValue]/60.0] font:[self.duringLabel.font fontWithSize:17] color:self.duringLabel.textColor andUnit:@"min" font:[self.duringLabel.font fontWithSize:14] color:self.duringLabel.textColor];
    self.trafficLightLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%ld", (long)[sum.traffic_light_jam_cnt integerValue]] font:[self.trafficLightLabel.font fontWithSize:17] color:self.trafficLightLabel.textColor andUnit:@"处" font:[self.trafficLightLabel.font fontWithSize:14] color:self.trafficLightLabel.textColor];
    
    UIColor * statusColor = COLOR_STAT_GREEN;
    eStepTraffic status = [[sum tripRoute] trafficStat];
    if (eStepTrafficVerySlow == status) {
        statusColor = COLOR_STAT_RED;
        self.statusBackground.image = [UIImage imageNamed:@"ticketred"];
    } else if (eStepTrafficSlow == status) {
        statusColor = COLOR_STAT_YELLOW;
        self.statusBackground.image = [UIImage imageNamed:@"ticketyellow"];
    } else {
        statusColor = COLOR_STAT_GREEN;
        self.statusBackground.image = [UIImage imageNamed:@"ticketgreen"];
    }
    
    self.distTextLabel.textColor = statusColor;
    self.timeTextLabel.textColor = statusColor;
    self.trafficTextLabel.textColor = statusColor;
    self.speedTextLabel.textColor = statusColor;
}

@end
