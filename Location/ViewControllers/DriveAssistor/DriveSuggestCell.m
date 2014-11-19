//
//  DriveSuggestCell.m
//  Location
//
//  Created by taq on 11/9/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "DriveSuggestCell.h"
#import "GPSTrafficAnalyzer.h"

@implementation DriveSuggestCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.cornerRadius = 10;
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.layer.borderWidth = 2;
    }
    return self;
}

- (NSString*) safeText:(NSString*)str withDefault:(NSString*)defaultStr
{
    return str.length > 0 ? str : defaultStr;
}

- (void) updateWithTripSummary:(TripSummary*)sum
{
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    
    self.toStreet.text = [self safeText:sum.region_group.end_region.street withDefault:@"未知地点"];
    self.toLabel.text = [self safeText:sum.region_group.end_region.nearby_poi withDefault:@"未知地点"];
    self.suggestLabel.text = [NSString stringWithFormat:@"%@ 建议出行", [formatter stringFromDate:sum.start_date]];
    
    NSArray * heavyTraffic = [GPSTrafficAnalyzer trafficJamsInTrip:sum withThreshold:cHeavyTrafficJamThreshold];
    self.jamCntLabel.text = [NSString stringWithFormat:@"%lu处拥堵", (unsigned long)heavyTraffic.count];
    self.jamDuringLabel.text = [NSString stringWithFormat:@"%d分钟", [sum.total_during intValue]/60];
}

@end
