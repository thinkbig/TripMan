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
    self.suggestLabel.text = [NSString stringWithFormat:@"%@ 建议出行", [formatter stringFromDate:sum.start_date]];
    
    self.jamCntLabel.text = [NSString stringWithFormat:@"%@处拥堵", sum.traffic_heavy_jam_cnt];
    self.jamDuringLabel.text = [NSString stringWithFormat:@"%d分钟", [sum.total_during intValue]/60];
}

@end

/////////////////////////////////////////////////////////////////////////////////

@implementation DriveSuggestPOICell

@end

/////////////////////////////////////////////////////////////////////////////////

@implementation SuggestPOICategoryCell

@end

/////////////////////////////////////////////////////////////////////////////////

@implementation SearchPOIHeader

@end
