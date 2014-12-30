//
//  DriveSuggestCell.m
//  Location
//
//  Created by taq on 11/9/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "DriveSuggestCell.h"
#import "TripSummary.h"
#import "RegionGroup.h"
#import "ParkingRegion.h"
#import "NSAttributedString+Style.h"

@implementation DriveSuggestCell

- (NSString*) safeText:(NSString*)str withDefault:(NSString*)defaultStr
{
    return str.length > 0 ? str : defaultStr;
}

- (void) updateWithTripSummary:(TripSummary*)sum
{
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    
    self.toStreet.text = [self safeText:sum.region_group.end_region.street withDefault:@"未知地点"];
    self.toLabel.text = [self safeText:sum.region_group.end_region.nearby_poi withDefault:@"未知地点"];
    
    self.suggestLabel.attributedText = [NSAttributedString stringWithNumber:[formatter stringFromDate:sum.start_date] font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"建议出行" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
    self.jamCntLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%@", sum.traffic_heavy_jam_cnt] font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"处拥堵" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
    
    self.jamDuringLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%d", [sum.total_during intValue]/60] font:DigitalFontSize(24) color:[UIColor blackColor] andUnit:@"min" font:DigitalFontSize(14) color:[UIColor blackColor]];
}

@end

/////////////////////////////////////////////////////////////////////////////////

@implementation DriveSuggestPOICell

- (void) useMockData
{
    self.destPOILabel.text = @"西湖文化广场";
    self.destStreetLabel.text = @"中山北路20号";
    
    NSTimeInterval during = 400.0;
    self.estimateDuringLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%d", (int)(during/60)] font:DigitalFontSize(24) color:[UIColor whiteColor] andUnit:@"min" font:DigitalFontSize(14) color:COLOR_UNIT_GRAY];
    self.duringStatusLabel.textColor = COLOR_STAT_GREEN;
}

@end

/////////////////////////////////////////////////////////////////////////////////

@implementation SuggestPOICategoryCell

@end

/////////////////////////////////////////////////////////////////////////////////

@implementation SearchPOIHeader

@end
