//
//  CarHomeViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarHomeViewController.h"

@interface CarHomeViewController ()

@property (nonatomic, strong) TripSummary *     mostTrip;

@end

@implementation CarHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"1234567890-1234567890-1234567890"];
//    [str addAttribute:NSBackgroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0,7)];
//    [str addAttribute:NSForegroundColorAttributeName value:[UIColor yellowColor] range:NSMakeRange(7,12)];
//    [str addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0] range:NSMakeRange(12, 20)];
//    self.suggestDistFrom.attributedText = str;
    
    
    // trip suggest info
    self.duringView.layer.cornerRadius = CGRectGetHeight(self.duringView.bounds)/2.0f;
    self.jamView.layer.cornerRadius = CGRectGetHeight(self.jamView.bounds)/2.0f;
    self.suggestView.layer.cornerRadius = CGRectGetHeight(self.suggestView.bounds)/2.0f;
    
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
    self.suggestDistFrom.text = [NSString stringWithFormat:@"距我的地点约 %.1fkm", [_mostTrip.total_dist floatValue]/1000.0];
    self.duringLabel.text = [NSString stringWithFormat:@"%.f", [_mostTrip.total_during floatValue]/60.0];
    self.jamLabel.text = [NSString stringWithFormat:@"%@", _mostTrip.traffic_jam_cnt];
    
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    self.suggestLabel.text = [formatter stringFromDate:_mostTrip.start_date];
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
