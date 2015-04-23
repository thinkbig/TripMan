//
//  SuggestDetailCell.m
//  TripMan
//
//  Created by taq on 11/24/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "SuggestDetailCell.h"
#import "ParkingRegion+Fetcher.h"
#import "BaiduReverseGeocodingWrapper.h"

@interface SuggestDetailCell ()

@property (nonatomic, strong) CTJam *       curJam;

@end

@implementation SuggestDetailCell

- (void) updateWithJam:(CTJam*)jam
{
    self.curJam = jam;
    if (jam) {
        eStepTraffic stat = [jam trafficStat];
        if (eStepTrafficSlow == stat) {
            self.jamStatBgImage.image = [UIImage imageNamed:@"roadcondition_tagyellow"];
            self.jamStatLabel.text = @"缓行";
        } else if (eStepTrafficVerySlow == stat) {
            self.jamStatBgImage.image = [UIImage imageNamed:@"roadcondition_tagred"];
            self.jamStatLabel.text = @"拥堵";
        } else {
            self.jamStatBgImage.image = [UIImage imageNamed:@"roadcondition_taggreen"];
            self.jamStatLabel.text = @"正常";
        }
        self.jamStatTitle.text = jam.intro.length > 0 ? jam.intro : @"-- --";
        self.jamStatSubTitle.text = nil;
        self.jamDurationLabel.text = [NSString stringWithFormat:@"%.f min", [jam.duration floatValue]/60.0];
    } else {
        self.jamStatBgImage.image = [UIImage imageNamed:@"roadcondition_taggreen"];
        self.jamStatLabel.text = @"正常";
    }
    
    if (jam && jam.intro.length == 0) {
        BaiduReverseGeocodingWrapper * wrapper = [BaiduReverseGeocodingWrapper new];
        wrapper.coordinate = [jam centerCoordenate];
        [wrapper requestWithSuccess:^(BMKReverseGeoCodeResult * result) {
            if (jam == self.curJam && result.addressDetail.streetName.length > 0) {
                jam.intro = result.addressDetail.streetName;
                self.jamStatTitle.text = jam.intro;
            }
        } failure:nil];
    }
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation SuggestDetailHeader

- (void) updateWithRoute:(CTRoute*)route
{
    self.destLabel.text = route.dest.name ? route.dest.name : @"目的地";
    self.totalDistLabel.text = route.distance ? [NSString stringWithFormat:@"%.fkm", [route.distance floatValue]/1000] : @"--";
    self.estimateDuringLabel.text = route.duration ? [NSString stringWithFormat:@"%.fmin", [route.duration floatValue]/60.0] : @"--";
    
    CGFloat during = [route.duration floatValue];
    if (during > 10) {
        NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
        self.endDateLabel.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:during]];
    } else {
        self.endDateLabel.text = @"00:00";
    }
}

- (void) updateWithTrip:(TripSummary*)sum
{
    self.destLabel.text = [sum.region_group.end_region nameWithDefault:@"未知地点"];
    self.totalDistLabel.text = [NSString stringWithFormat:@"%.1f",[sum.total_dist floatValue]/1000.0];
    self.estimateDuringLabel.text = [NSString stringWithFormat:@"%.f",[sum.total_during floatValue]/60.0];
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    self.endDateLabel.text = [formatter stringFromDate:sum.end_date];
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation SuggestPredictCell

- (void) updateWithStartTime:(NSDate*)stDate andDuration:(NSTimeInterval)duration
{
    if (stDate) {
        NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
        self.startTimeLabel.text = [formatter stringFromDate:stDate];
        self.predictDurationLabel.text = [NSString stringWithFormat:@"%.fmin", duration/60.0];
    } else {
        self.startTimeLabel.text = @"00:00";
        self.predictDurationLabel.text = @"--";
    }
}

@end


