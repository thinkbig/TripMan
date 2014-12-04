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
    return 2;
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
        CGFloat dist = [_tripSum.traffic_jam_dist floatValue]/1000.0;
        if (dist >= 10) {
            [realCell setJamDistStr:[NSString stringWithFormat:@"%.f", dist]];
        } else {
            [realCell setJamDistStr:[NSString stringWithFormat:@"%.1f", dist]];
        }
        [realCell setJamDuringStr:[NSString stringWithFormat:@"%.f", [_tripSum.traffic_jam_during floatValue]/60.0]];
        [realCell setJamAvgSpeedStr:[NSString stringWithFormat:@"%.1f", [_tripSum.traffic_avg_speed floatValue]*3.6]];
        [realCell setJamCountStr:[NSString stringWithFormat:@"%ld", (long)[_tripSum.traffic_heavy_jam_cnt integerValue]]];
        cell = realCell;
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.row) {
        return CGSizeMake(320.f, 200.f);
    } else if (1 == indexPath.row) {
        return CGSizeMake(320.f, 150.f);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 1.0f;
}

@end
