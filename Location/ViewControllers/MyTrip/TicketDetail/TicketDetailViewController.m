//
//  TicketDetailViewController.m
//  TripMan
//
//  Created by taq on 11/25/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TicketDetailViewController.h"
#import "TicketDetailCell.h"
#import "DrivingInfo.h"
#import "MapDisplayViewController.h"

@interface TicketDetailViewController ()

@property (nonatomic, strong) NSArray *         speedSegs;

@end

@implementation TicketDetailViewController

- (void)awakeFromNib {
    if (nil == self.speedSegs) {
        self.speedSegs = @[@100, @0, @0, @0];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTripSum:(TripSummary *)tripSum
{
    _tripSum = tripSum;
    
    DrivingInfo * info = tripSum.driving_info;
    CGFloat allDuring = [info.during_0_30 floatValue] + [info.during_30_60 floatValue] + [info.during_60_100 floatValue] + [info.during_100_NA floatValue];
    if (allDuring == 0) {
        self.speedSegs = @[@100, @0, @0, @0];
    } else {
        allDuring /= 100.0;
        self.speedSegs = @[@([info.during_0_30 floatValue]/allDuring), @([info.during_30_60 floatValue]/allDuring), @([info.during_60_100 floatValue]/allDuring), @([info.during_100_NA floatValue]/allDuring)];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 5;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (0 == indexPath.row) {
        TicketDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DetailSummaryCell" forIndexPath:indexPath];
        realCell.chartArr = self.speedSegs;
        CGFloat dist = [_tripSum.total_dist floatValue]/1000.0;
        if (dist >= 10) {
            [realCell setTolDistStr:[NSString stringWithFormat:@"%.f", dist]];
        } else {
            [realCell setTolDistStr:[NSString stringWithFormat:@"%.1f", dist]];
        }
        [realCell setTolDuringStr:[NSString stringWithFormat:@"%.f", [_tripSum.total_during floatValue]/60.0]];
        [realCell setAvgSpeedStr:[NSString stringWithFormat:@"%.1f", [_tripSum.avg_speed floatValue]*3.6]];
        [realCell setMaxSpeedStr:[NSString stringWithFormat:@"%.1f", [_tripSum.max_speed floatValue]*3.6]];
        
        cell = realCell;
    } else if (1 == indexPath.row) {
        TicketJamDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JamDetailCell" forIndexPath:indexPath];
        realCell.cellTitle.text = @"缓行数据";
        
        CGFloat dist = [_tripSum.traffic_jam_dist floatValue]/1000.0;
        NSString * distStr = nil;
        if (dist >= 10) {
            distStr = [NSString stringWithFormat:@"%.f", dist];
        } else {
            distStr = [NSString stringWithFormat:@"%.1f", dist];
        }
        [realCell setLabel11Str:@"缓行公里数" withValue:distStr andUnit:@"km"];
        [realCell setLabel21Str:@"缓行总耗时" withValue:[NSString stringWithFormat:@"%.f", [_tripSum.traffic_jam_during floatValue]/60.0] andUnit:@"min"];
        [realCell setLabel22Str:@"缓行速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.traffic_avg_speed floatValue]*3.6] andUnit:@"km/h"];
        [realCell setLabel23Str:@"拥堵点" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.traffic_heavy_jam_cnt integerValue]] andUnit:@"个"];

        cell = realCell;
    } else if (2 == indexPath.row) {
        TicketJamDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JamDetailCell" forIndexPath:indexPath];
        realCell.cellTitle.text = @"红绿灯数据";
        [realCell setLabel11Str:@"通过红绿灯数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.traffic_light_tol_cnt integerValue]] andUnit:@"个"];
        [realCell setLabel21Str:@"等待个数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.traffic_light_jam_cnt floatValue]] andUnit:@"个"];
        [realCell setLabel22Str:@"等待耗时" withValue:[NSString stringWithFormat:@"%.f", (long)[_tripSum.traffic_light_waiting floatValue]/60.0] andUnit:@"min"];
        [realCell setLabel23Str:@"单次最长等待" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.traffic_jam_max_during floatValue]/60.0] andUnit:@"min"];
        
        cell = realCell;
    } else if (3 == indexPath.row) {
        TicketDriveDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TicketDriveDetailCellId" forIndexPath:indexPath];
        realCell.cellTitle.text = @"转弯数据";
        
        [realCell setLabel11Str:@"右转弯次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.turning_info.right_turn_cnt integerValue]] andUnit:@"个"];
        [realCell setLabel12Str:@"平均速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.turning_info.right_turn_avg_speed floatValue]*3.6] andUnit:@"km/h"];
        [realCell setLabel13Str:@"最大速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.turning_info.right_turn_max_speed floatValue]*3.6] andUnit:@"km/h"];
        
        [realCell setLabel21Str:@"左转弯次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.turning_info.left_turn_cnt integerValue]] andUnit:@"个"];
        [realCell setLabel22Str:@"平均速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.turning_info.left_turn_avg_speed floatValue]*3.6] andUnit:@"km/h"];
        [realCell setLabel23Str:@"最大速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.turning_info.left_turn_max_speed floatValue]*3.6] andUnit:@"km/h"];
        
        cell = realCell;
    } else if (4 == indexPath.row) {
        TicketDriveDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TicketDriveDetailCellId" forIndexPath:indexPath];
        realCell.cellTitle.text = @"加速减速";
        
        [realCell setLabel11Str:@"加速次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.driving_info.acce_cnt integerValue]] andUnit:@"次"];
        [realCell setLabel12Str:@"深度加速次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.driving_info.hard_acce_cnt integerValue]] andUnit:@"次"];
        [realCell setLabel13Str:@"5秒最大加速" withValue:[NSString stringWithFormat:@"%.1f", 3.6*([_tripSum.driving_info.max_acce_end_speed floatValue] - [_tripSum.driving_info.max_acce_begin_speed floatValue])] andUnit:@"km/h"];
        
        [realCell setLabel21Str:@"刹车次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.driving_info.acce_cnt integerValue]] andUnit:@"次"];
        [realCell setLabel22Str:@"深度刹车次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.driving_info.hard_breaking_cnt integerValue]] andUnit:@"次"];
        [realCell setLabel23Str:@"5秒最大减速" withValue:[NSString stringWithFormat:@"%.1f", -3.6*([_tripSum.driving_info.max_breaking_end_speed floatValue] - [_tripSum.driving_info.max_breaking_begin_speed floatValue])] andUnit:@"km/h"];
        
        cell = realCell;
    }
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor clearColor];
    } else {
        cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.row) {
        return CGSizeMake(320.f, 200.f);
    } else if (indexPath.row >= 1 && indexPath.row <= 4) {
        return CGSizeMake(320.f, 150.f);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.row) {
        MapDisplayViewController * mapVC = [[UIStoryboard storyboardWithName:@"Debug" bundle:nil] instantiateViewControllerWithIdentifier:@"MapDisplayView"];
        mapVC.tripSum = self.tripSum;
        [self.navigationController presentViewController:mapVC animated:YES completion:nil];
    }
}

@end
