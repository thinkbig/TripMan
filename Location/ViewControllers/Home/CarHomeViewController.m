//
//  CarHomeViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarHomeViewController.h"
#import "NSDate+Utilities.h"
#import "HomeTripCell.h"
#import "NSAttributedString+Style.h"

@interface CarHomeViewController ()

@property (nonatomic, strong) TripSummary *     mostTrip;
@property (nonatomic, strong) HomeTripHeader *  header;
@property (nonatomic, strong) HomeTripCell *    tripCell;
@property (nonatomic, strong) HomeHealthCell *  healthCell;

@end

@implementation CarHomeViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadContent) name:kNotifyNeedUpdate object:nil];
    
    [self reloadContent];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadContent];
}

- (void) reloadContent
{
    if (IS_UPDATING) {
        return;
    }
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (curLoc) {
        ParkingRegionDetail * parkingDetail = [[TripsCoreDataManager sharedManager] parkingDetailForCoordinate:curLoc.coordinate];
        NSArray * mostTrips = [[TripsCoreDataManager sharedManager] tripsWithStartRegion:parkingDetail.coreDataItem tripLimit:1];
        if (mostTrips.count > 0) {
            self.mostTrip = mostTrips[0];
        }
    }
    
    [self.homeCollection reloadData];
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

- (void) updateHeader
{
    if (IS_UPDATING) {
        return;
    }
    NSString * destStr = _mostTrip.region_group.end_region.nearby_poi;
    if (_mostTrip.region_group.end_region.street) {
        if (destStr) {
            destStr = [NSString stringWithFormat:@"%@ %@", _mostTrip.region_group.end_region.street, destStr];
        } else {
            destStr = _mostTrip.region_group.end_region.street;
        }
    }
    self.header.suggestDest.text = destStr.length > 0 ? destStr : @"未知地点";
    NSString * mostDest = [NSString stringWithFormat:@"距我的地点约 %.1fkm", [_mostTrip.total_dist floatValue]/1000.0];
    NSMutableAttributedString * mostTripDest = [[NSMutableAttributedString alloc] initWithString:mostDest];
    [mostTripDest addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x82d13a) range:NSMakeRange(6, mostDest.length-6)];
    [mostTripDest addAttribute:NSFontAttributeName value:DigitalFontSize(13) range:NSMakeRange(6, mostDest.length-6)];
    self.header.suggestDistFrom.attributedText = mostTripDest;
}

- (void) updateTrip
{
    if (IS_UPDATING) {
        return;
    }
    // set during
    self.tripCell.duringLabel.text = [NSString stringWithFormat:@"%02d", (int)([_mostTrip.total_during floatValue]/60.0)];
    
    // most trip info
    self.tripCell.jamLabel.text = [NSString stringWithFormat:@"%ld", (long)[_mostTrip.traffic_heavy_jam_cnt integerValue]];
    
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    self.tripCell.suggestLabel.text = _mostTrip.start_date ? [formatter stringFromDate:_mostTrip.start_date] : @"00:00";
    
}

- (void) updateHealth
{
    if (IS_UPDATING) {
        return;
    }
    // update today trip summary
    DaySummary * daySum = [[TripsCoreDataManager sharedManager] daySummaryByDay:nil];
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeDaySum:daySum];

    CGFloat totalDist = [daySum.total_dist floatValue];
    CGFloat totalDuring = [daySum.total_during floatValue];
    
    NSString * rawStr = [NSString stringWithFormat:@"%.1f km  %.f min", totalDist/1000.0, totalDuring/60.0];
    NSRange kmRange = [rawStr rangeOfString:@" km "];
    NSRange minRange = [rawStr rangeOfString:@" min"];
    NSMutableAttributedString *todayStr = [[NSMutableAttributedString alloc] initWithString:rawStr];
    [todayStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x7bce33) range:NSMakeRange(0, kmRange.location)];
    [todayStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x7bce33) range:NSMakeRange(kmRange.location+kmRange.length, minRange.location-(kmRange.location+kmRange.length))];
    [todayStr addAttribute:NSFontAttributeName value:DigitalFontSize(14) range:NSMakeRange(0, kmRange.location)];
    [todayStr addAttribute:NSFontAttributeName value:DigitalFontSize(14) range:NSMakeRange(kmRange.location+kmRange.length, minRange.location-(kmRange.location+kmRange.length))];
    
    self.healthCell.todayTripSum.attributedText = todayStr;
    
    // update illegal
    UIFont * font12 = [UIFont boldSystemFontOfSize:11];
    self.healthCell.IllegalCount.attributedText = [NSAttributedString stringWithNumber:@"0" font:DigitalFontSize(14) color:COLOR_STAT_RED andUnit:@" 新违章" font:font12 color:[UIColor whiteColor]];
    self.healthCell.IllegalPendingCount.attributedText = [NSAttributedString stringWithNumber:@"0" font:DigitalFontSize(14) color:COLOR_STAT_RED andUnit:@" 未处理违章" font:font12 color:[UIColor whiteColor]];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = nil;
    if (0 == indexPath.section)
    {
        if (0 == indexPath.row) {
            self.tripCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeTripCellId" forIndexPath:indexPath];
            [self updateTrip];
            cell = self.tripCell;
        } else {
            self.healthCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeHealthCellId" forIndexPath:indexPath];
            [self updateHealth];
            cell = self.healthCell;
        }
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView* reusableView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        self.header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeTripHeaderId" forIndexPath:indexPath];
        [self updateHeader];
        reusableView = self.header;
    }
    
    return reusableView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.section) {
        if (0 == indexPath.row) {
            return CGSizeMake(320, 270);
        } else {
            return CGSizeMake(320, 180);
        }
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
{
    if (0 == section) {
        return CGSizeMake(320, 80);
    }
    return CGSizeZero;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{

}

@end
