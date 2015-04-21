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
#import "DaySummary+Fetcher.h"
#import "ParkingRegion+Fetcher.h"
#import "TripFilter.h"
#import "CTTrafficAbstractFacade.h"
#import "SuggestDetailViewController.h"

@interface CarHomeViewController ()

@property (nonatomic, strong) CTRoute *                 bestRoute;
@property (nonatomic, strong) ParkingRegion *           bestGuessDest;
@property (nonatomic, strong) TripSummary *             bestTrip;

@property (nonatomic, strong) HomeTripHeader *          header;
@property (nonatomic, strong) HomeTripCell *            tripCell;
@property (nonatomic, strong) HomeHealthCell *          healthCell;

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

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    [self reloadContent];
}

- (void) reloadContent
{
    if (IS_UPDATING) {
        return;
    }
    
    self.bestTrip = nil;
    NSArray * guessTrips = [[BussinessDataProvider sharedInstance] bestGuessLocations:1 formatToDetail:NO];
    if (guessTrips.count > 0) {
        id guessData = guessTrips[0];
        if ([guessData isKindOfClass:[TripSummary class]]) {
            self.bestTrip = guessData;
        }
        if (self.bestTrip) {
            self.bestGuessDest = self.bestTrip.region_group.end_region;
        } else {
            if ([guessData isKindOfClass:[ParkingRegionDetail class]]) {
                self.bestGuessDest = ((ParkingRegionDetail*)guessData).coreDataItem;
            } else if ([guessData isKindOfClass:[ParkingRegion class]]) {
                self.bestGuessDest = guessData;
            }
        }
        
        CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
        if (curLoc) {
            if (self.bestGuessDest) {
                ParkingRegionDetail * parkingDetail = [[AnaDbManager sharedInst] parkingDetailForCoordinate:curLoc.coordinate minDist:500];
                CTTrafficAbstractFacade * facade = [[CTTrafficAbstractFacade alloc] init];
                facade.fromCoorBaidu = [GeoTransformer earth2Baidu:curLoc.coordinate];
                facade.toCoorBaidu = [GeoTransformer earth2Baidu:self.bestGuessDest.centerCoordinate];
                if (parkingDetail) {
                    facade.fromParkingId = parkingDetail.coreDataItem.parking_id;
                    facade.toParkingId = self.bestGuessDest.parking_id;
                }
                [facade requestWithSuccess:^(CTRoute * result) {
                    self.bestRoute = result;
                    [self.homeCollection reloadData];
                } failure:^(NSError * err) {
                    //NSLog(@"asdfasdf = %@", err);
                }];
            }
        }
        
        [self.homeCollection reloadData];
    }
    
//    self.bestTrip = nil;
//    NSDate * now = [NSDate date];
//    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
//    if (curLoc) {
//        ParkingRegionDetail * parkingDetail = [[AnaDbManager sharedInst] parkingDetailForCoordinate:curLoc.coordinate minDist:500];
//        NSArray * mostTrips = [[AnaDbManager sharedInst] tripsWithStartRegion:parkingDetail.coreDataItem tripLimit:10 startDate:now];
//        if (mostTrips.count > 0) {
//            self.bestTrip = mostTrips[0];
//            NSArray * timeFilterArr = [TripFilter filterTrips:mostTrips byTime:now between:-60 toMinute:60];
//            if (timeFilterArr.count > 0) {
//                self.bestTrip = timeFilterArr[0];
//                NSArray * weekendFilterArr = [TripFilter filterTrips:mostTrips byDayType:[TripFilter dayTypeByDate:now]];
//                if (weekendFilterArr.count > 0) {
//                    self.bestTrip = weekendFilterArr[0];
//                }
//            }
//        }
//        if (nil == self.bestTrip) {
//            // 取这次旅程的起点作为猜测
//            TripSummary * lastTrip = [[AnaDbManager sharedInst] lastTrip];
//            if (lastTrip && lastTrip.region_group.start_region != lastTrip.region_group.end_region) {
//                self.bestGuessDest = lastTrip.region_group.start_region;
//            }
//        } else {
//            self.bestGuessDest = self.bestTrip.region_group.end_region;
//        }
//        
//        if (nil == self.bestGuessDest) {
//            // 所以停车位置中，去过最多的那个作为猜测，去除当前位置点
//            NSArray * parkLoc = [[AnaDbManager sharedInst] mostUsedParkingRegionLimit:2];
//            for (ParkingRegionDetail * locDetail in parkLoc) {
//                if (parkingDetail != locDetail) {
//                    self.bestGuessDest = locDetail.coreDataItem;
//                    break;
//                }
//            }
//        }
//        
//        if (self.bestGuessDest) {
//            CTTrafficAbstractFacade * facade = [[CTTrafficAbstractFacade alloc] init];
//            facade.fromCoorBaidu = [GeoTransformer earth2Baidu:curLoc.coordinate];
//            facade.toCoorBaidu = [GeoTransformer earth2Baidu:self.bestGuessDest.centerCoordinate];
//            if (parkingDetail) {
//                facade.fromParkingId = parkingDetail.coreDataItem.parking_id;
//                facade.toParkingId = self.bestGuessDest.parking_id;
//            }
//            [facade requestWithSuccess:^(CTRoute * result) {
//                self.bestRoute = result;
//                [self.homeCollection reloadData];
//            } failure:^(NSError * err) {
//                //NSLog(@"asdfasdf = %@", err);
//            }];
//        }
//    }
//    
//    [self.homeCollection reloadData];
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
    
    if (self.bestGuessDest) {
        NSString * destStr = [self.bestGuessDest nameWithDefault:nil];
        if (self.bestGuessDest.street) {
            if (destStr) {
                destStr = [NSString stringWithFormat:@"%@ %@", self.bestGuessDest.street, destStr];
            } else {
                destStr = self.bestGuessDest.street;
            }
        }
        self.header.suggestDest.text = destStr.length > 0 ? destStr : @"未知地点";
        NSString * mostDest = nil;
        if (self.bestRoute) {
            mostDest = [NSString stringWithFormat:@"距我的地点约 %.1fkm", [self.bestRoute.distance floatValue]/1000.0];
        } else if (self.bestTrip) {
            mostDest = [NSString stringWithFormat:@"距我的地点约 %.1fkm", [self.bestTrip.total_dist floatValue]/1000.0];
        } else {
            mostDest = @"距我的地点约 --km";
        }
        NSMutableAttributedString * mostTripDest = [[NSMutableAttributedString alloc] initWithString:mostDest];
        [mostTripDest addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x82d13a) range:NSMakeRange(6, mostDest.length-6)];
        [mostTripDest addAttribute:NSFontAttributeName value:DigitalFontSize(13) range:NSMakeRange(6, mostDest.length-6)];
        self.header.suggestDistFrom.attributedText = mostTripDest;
    } else {
        self.header.suggestDest.text = @"当前位置";
        self.header.suggestDistFrom.text = @"您还没有行程记录";
    }
}

- (void) updateTrip
{
    if (IS_UPDATING) {
        return;
    }
    
    if (self.bestRoute)
    {
        self.tripCell.duringLabel.text = [NSString stringWithFormat:@"%02d", (int)([self.bestRoute.duration floatValue]/60.0)];
        BOOL hasJam = [self.bestRoute.most_jam.duration floatValue] > cTrafficJamThreshold;
        self.tripCell.jamLabel.text = [NSString stringWithFormat:@"%ld", (long)hasJam];
        NSDate * dateNow = [NSDate date];
        NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
        self.tripCell.suggestLabel.text = dateNow ? [formatter stringFromDate:dateNow] : @"00:00";
    }
    else
    {
        self.tripCell.duringLabel.text = @"--";
        self.tripCell.jamLabel.text = @"-";
        self.tripCell.suggestLabel.text = @"--:--";
    }
    
    self.tripCell.statusLabel.text = @"目前道路无特殊情况";
    self.tripCell.statusColorView.backgroundColor = COLOR_STAT_GREEN;
    if (self.bestRoute.most_jam) {
        eStepTraffic status = [self.bestRoute.most_jam trafficStat];
        if (self.bestRoute.most_jam.intro) {
            self.tripCell.statusLabel.text = self.bestRoute.most_jam.intro;
        } else {
            if (status == eStepTrafficVerySlow) {
                self.tripCell.statusLabel.text = @"旅程有拥堵";
            } else if (status == eStepTrafficSlow) {
                self.tripCell.statusLabel.text = @"车多缓行";
            }
        }
        self.tripCell.statusColorView.backgroundColor = [CTJam colorFromTraffic:status];
    }
}

- (void) updateHealth
{
    if (IS_UPDATING) {
        return;
    }
    // update today trip summary
    DaySummary * daySum = [[AnaDbManager deviceDb] daySummaryByDay:nil];
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeDaySum:daySum];
    CGFloat totalDist = [daySum.total_dist floatValue];
    CGFloat totalDuring = [daySum.total_during floatValue];
    
    DaySummary * histDaySum = [[AnaDbManager sharedInst] userDaySumForDeviceDaySum:daySum];
    if (histDaySum) {
        totalDist += [histDaySum.total_dist floatValue];
        totalDuring += [histDaySum.total_during floatValue];
    }
    
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
    
    self.healthCell.carMaintainProgress.progressFillColor = COLOR_STAT_RED;
}

- (void) gotoDetail:(ParkingRegion*)region fromLoc:(CLLocation*)curLoc
{
    CTRoute * route = [CTRoute new];
    [route setCoorType:eCoorTypeBaidu];
    route.orig.name = @"当前位置";
    [route.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
    route.dest.name = [region nameWithDefault:@"目的地"];
    [route.dest updateWithCoordinate:[GeoTransformer earth2Baidu:[region centerCoordinate]]];

    SuggestDetailViewController * suggestDetail = InstVC(@"CarAssistor", @"SuggestDetailID");
    suggestDetail.route = route;
    suggestDetail.endParkingId = region.parking_id;
    [self.navigationController pushViewController:suggestDetail animated:YES];
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
    if (0 == indexPath.section) {
        if (0 == indexPath.row) {
            CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
            if (curLoc) {
                [self gotoDetail:self.bestGuessDest fromLoc:curLoc];
            } else {
                [self showToast:@"当前gps不可用" onDismiss:nil];
            }
        }
    }
}

@end
