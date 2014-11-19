//
//  CarHomeViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarHomeViewController.h"
#import "NSDate+Utilities.h"
#import "GPSTrafficAnalyzer.h"

@interface CarHomeViewController ()

@property (nonatomic, strong) TripSummary *     mostTrip;

@end

@implementation CarHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // trip suggest info
    self.duringView.layer.cornerRadius = CGRectGetHeight(self.duringView.bounds)/2.0f;
    self.jamView.layer.cornerRadius = CGRectGetHeight(self.jamView.bounds)/2.0f;
    self.suggestView.layer.cornerRadius = CGRectGetHeight(self.suggestView.bounds)/2.0f;
    
    // status view
    self.statusView.layer.cornerRadius = 4;
    self.statusColorView.layer.cornerRadius = 4;
    
    // car health chart
    self.carHealthProgress.showText = NO;
    self.carHealthProgress.progress = 0.7;
    self.carHeathLabel.layer.cornerRadius = CGRectGetHeight(self.carHeathLabel.bounds)/2.0f;
    
    // car maintain chart
    self.carMaintainProgress.showText = NO;
    self.carMaintainProgress.progress = 0.7;
    self.carMaintainProgress.progressFillColor = [UIColor orangeColor];
    self.carMaintainLabel.backgroundColor = [UIColor orangeColor];
    self.carMaintainLabel.layer.cornerRadius = CGRectGetHeight(self.carMaintainLabel.bounds)/2.0f;
    
    [self reloadContent];

}

- (void) reloadContent
{
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (curLoc) {
        ParkingRegionDetail * parkingDetail = [[TripsCoreDataManager sharedManager] parkingDetailForCoordinate:curLoc.coordinate];
        NSArray * mostTrips = [[TripsCoreDataManager sharedManager] tripsWithStartRegion:parkingDetail.coreDataItem tripLimit:1];
        if (mostTrips.count > 0) {
            self.mostTrip = mostTrips[0];
        }
    }
    NSString * destStr = _mostTrip.region_group.end_region.nearby_poi;
    if (_mostTrip.region_group.end_region.street) {
        if (destStr) {
            destStr = [NSString stringWithFormat:@"%@ %@", _mostTrip.region_group.end_region.street, destStr];
        } else {
            destStr = _mostTrip.region_group.end_region.street;
        }
    }
    self.suggestDest.text = destStr ? destStr : @"未知地点";
    NSString * mostDest = [NSString stringWithFormat:@"距我的地点约%.1fkm", [_mostTrip.total_dist floatValue]/1000.0];
    NSMutableAttributedString * mostTripDest = [[NSMutableAttributedString alloc] initWithString:mostDest];
    [mostTripDest addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x82d13a) range:NSMakeRange(6, mostDest.length-6)];
    self.suggestDistFrom.attributedText = mostTripDest;
    
    // most trip info
    self.duringLabel.text = [NSString stringWithFormat:@"%.f", [_mostTrip.total_during floatValue]/60.0];
    NSArray * heavyTraffic = [GPSTrafficAnalyzer trafficJamsInTrip:_mostTrip withThreshold:cHeavyTrafficJamThreshold];
    self.jamLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)heavyTraffic.count];
    
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    self.suggestLabel.text = [formatter stringFromDate:_mostTrip.start_date];
    
    // update today trip summary
    NSDate * dateDay = [NSDate date];
    NSArray * trips = [[TripsCoreDataManager sharedManager] tripStartFrom:[dateDay dateAtStartOfDay] toDate:[dateDay dateAtEndOfDay]];
    
    CGFloat totalDist = 0;
    CGFloat totalDuring = 0;
    
    for (TripSummary * sum in trips) {
        totalDist += [sum.total_dist floatValue];
        totalDuring += [sum.total_during floatValue];
    }
    
    NSString * rawStr = [NSString stringWithFormat:@"%.1f km %.f min", totalDist/1000.0, totalDuring/60.0];
    NSRange kmRange = [rawStr rangeOfString:@" km "];
    NSRange minRange = [rawStr rangeOfString:@" min"];
    NSMutableAttributedString *todayStr = [[NSMutableAttributedString alloc] initWithString:rawStr];
    [todayStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x82d13a) range:NSMakeRange(0, kmRange.location)];
    [todayStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x82d13a) range:NSMakeRange(kmRange.location+kmRange.length, minRange.location-(kmRange.location+kmRange.length))];
    [todayStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14] range:NSMakeRange(0, kmRange.location)];
    [todayStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14] range:NSMakeRange(kmRange.location+kmRange.length, minRange.location-(kmRange.location+kmRange.length))];
    
    self.todayTripSum.attributedText = todayStr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
