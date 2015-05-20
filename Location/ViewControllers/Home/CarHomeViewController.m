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
#import "BaiduPOISearchWrapper.h"
#import "BaiduReverseGeocodingWrapper.h"
#import "CarMaintainInfoViewController.h"

@interface CarHomeViewController ()

@property (nonatomic, strong) CTRoute *                 bestRoute;
@property (nonatomic, strong) ParkingRegion *           bestGuessDest;
@property (nonatomic, strong) TripSummary *             bestTrip;
@property (nonatomic, strong) BMKPoiInfo *              defaultDest;

@property (nonatomic, strong) HomeTripHeader *          header;
@property (nonatomic, strong) HomeTripCell *            tripCell;
@property (nonatomic, strong) HomeHealthCellNew *       healthCell;

@property (nonatomic, strong) CLLocation *              lastRecordLoc;

@end

@implementation CarHomeViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadContent) name:kNotifyNeedUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation) name:kNotifyGoodLocationUpdated object:nil];
    
    if (nil == self.maintainInfo) {
        self.maintainInfo = [[CarMaintainInfo alloc] init];
        [self.maintainInfo load];
        [self.maintainInfo updateDynamicInfo];
    }
    
    [self reloadContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    [self.maintainInfo updateDynamicInfo];
    [self reloadContent];
}

- (void) reloadContent
{
    if (IS_UPDATING) {
        return;
    }
    
    self.bestTrip = nil;
    NSArray * guessTrips = [[BussinessDataProvider sharedInstance] bestGuessLocations:1 formatToDetail:NO thresDist:IGNORE_NAVIGATION_DIST];
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
    }
    
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (curLoc)
    {
        [self showLoading];
        self.lastRecordLoc = curLoc;
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
                [self hideLoading];
                self.bestRoute = result;
                [self.homeCollection reloadData];
            } failure:^(NSError * err) {
                [self hideLoading];
                //NSLog(@"asdfasdf = %@", err);
            }];
        } else {
            [[BussinessDataProvider sharedInstance] updateCurrentCity:^(NSString * city) {
                if (city) {
                    BaiduPOISearchWrapper * wrapper = [BaiduPOISearchWrapper new];
                    wrapper.city = city;
                    wrapper.searchName = @"商圈";
                    [wrapper requestWithSuccess:^(BMKPoiResult * result) {
                        if (result.poiInfoList.count > 0) {
                            BMKPoiInfo * info = result.poiInfoList[0];
                            for (BMKPoiInfo * oneInfo in result.poiInfoList) {
                                CLLocation * infoLoc = [[CLLocation alloc] initWithLatitude:oneInfo.pt.latitude longitude:oneInfo.pt.longitude];
                                CGFloat dist = [curLoc distanceFromLocation:infoLoc];
                                if (dist < 400 || dist > 20*1000) {
                                    continue;
                                }
                                info = oneInfo;
                                break;
                            }
                            
                            self.defaultDest = info;
                            
                            CTTrafficAbstractFacade * facade = [[CTTrafficAbstractFacade alloc] init];
                            facade.fromCoorBaidu = [GeoTransformer earth2Baidu:curLoc.coordinate];
                            facade.toCoorBaidu = info.pt;
                            
                            [facade requestWithSuccess:^(CTRoute * result) {
                                [self hideLoading];
                                self.bestRoute = result;
                                [self.homeCollection reloadData];
                            } failure:^(NSError * err) {
                                [self hideLoading];
                            }];
                        } else {
                            [self hideLoading];
                        }
                    } failure:^(NSError * err) {
                        [self hideLoading];
                        NSLog(@"fail to get baidu poi info for 商圈");
                    }];
                } else {
                    [self hideLoading];
                }
            } forceUpdate:YES];
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

- (void) updateUserLocation
{
    if (self.lastRecordLoc) {
        CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
        if ([curLoc distanceFromLocation:self.lastRecordLoc] < 500) {
            return;
        }
    }
    [self reloadContent];
}

- (void) tapHealth {
    [self tapMaintain];
}

- (void) tapMaintain {
    CarMaintainInfoViewController * maintainVC = InstVC(@"EditCarinfo", @"CarMaintainInfoViewController");
    maintainVC.maintainInfo = self.maintainInfo;
    [self.navigationController pushViewController:maintainVC animated:YES];
}

- (void) updateHeader
{
    if (IS_UPDATING) {
        return;
    }
    
    if (self.bestRoute) {
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
        self.header.suggestDistFrom.text = @"您还没有行程记录";
    }
    
    if (self.bestGuessDest)
    {
        NSString * destStr = [self.bestGuessDest nameWithDefault:nil];
        if (self.bestGuessDest.street) {
            if (destStr) {
                destStr = [NSString stringWithFormat:@"%@ %@", self.bestGuessDest.street, destStr];
            } else {
                destStr = self.bestGuessDest.street;
            }
        }
        self.header.suggestDest.text = destStr.length > 0 ? destStr : @"未知地点";
    }
    else if (self.defaultDest)
    {
        NSString * destStr = self.defaultDest.name;
        self.header.suggestDest.text = destStr.length > 0 ? destStr : @"未知地点";
    }
    else
    {
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
        NSDate * dateArrive = [NSDate dateWithTimeIntervalSinceNow:[self.bestRoute.duration floatValue]];
        NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
        self.tripCell.suggestLabel.text = dateArrive ? [formatter stringFromDate:dateArrive] : @"00:00";
    }
    else
    {
        self.tripCell.duringLabel.text = @"--";
        self.tripCell.jamLabel.text = @"-";
        self.tripCell.suggestLabel.text = @"--:--";
    }
    
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (nil == curLoc) {
        self.tripCell.statusLabel.text = @"GPS可能正在启动中...";
        return;
    }
    
    self.tripCell.statusLabel.text = @"目前道路无特殊情况";
    self.tripCell.statusColorView.backgroundColor = COLOR_STAT_GREEN;
    self.tripCell.jamImageView.image = [UIImage imageNamed:@"greenball"];
    if (self.bestRoute.most_jam) {
        [self.bestRoute.most_jam calCoefWithStartLoc:[self.bestRoute.orig clLocation] andEndLoc:[self.bestRoute.dest clLocation]];

        eStepTraffic status = [self.bestRoute.most_jam trafficStat];
        if (self.bestRoute.most_jam.intro.length > 0) {
            self.tripCell.statusLabel.text = self.bestRoute.most_jam.intro;
        } else {
            if (status == eStepTrafficVerySlow) {
                self.tripCell.statusLabel.text = @"旅程有拥堵";
                self.tripCell.jamImageView.image = [UIImage imageNamed:@"redball"];
            } else if (status == eStepTrafficSlow) {
                self.tripCell.statusLabel.text = @"车多缓行";
                self.tripCell.jamImageView.image = [UIImage imageNamed:@"yellowball"];
            }
        }
        self.tripCell.statusColorView.backgroundColor = [CTJam colorFromTraffic:status];
        
        CTJam * curJam = self.bestRoute.most_jam;
        BaiduReverseGeocodingWrapper * wrapper = [BaiduReverseGeocodingWrapper new];
        wrapper.coordinate = [curJam centerCoordenate];
        [wrapper requestWithSuccess:^(BMKReverseGeoCodeResult * result) {
            if (curJam == self.bestRoute.most_jam && result.addressDetail.streetName.length > 0) {
                curJam.intro = result.addressDetail.streetName;
                if (curJam.intro.length > 0) {
                    if (status == eStepTrafficVerySlow) {
                        self.tripCell.statusLabel.text = [NSString stringWithFormat:@"%@ 有拥堵", curJam.intro];
                    } else if (status == eStepTrafficSlow) {
                        self.tripCell.statusLabel.text = [NSString stringWithFormat:@"%@ 有缓行", curJam.intro];
                    }
                }
            }
        } failure:nil];
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
    
    NSString * rawDistStr = [NSString stringWithFormat:@"%.f km", totalDist/1000.0];
    NSRange kmRange = [rawDistStr rangeOfString:@" km"];
    NSMutableAttributedString *distStr = [[NSMutableAttributedString alloc] initWithString:rawDistStr];
    [distStr addAttribute:NSForegroundColorAttributeName value:COLOR_STAT_GREEN range:NSMakeRange(0, kmRange.location)];
    [distStr addAttribute:NSFontAttributeName value:DigitalFontSize(20) range:NSMakeRange(0, kmRange.location)];
    self.healthCell.todayTripSum.attributedText = distStr;
    
    NSString * rawDurationStr = [NSString stringWithFormat:@"%.f min", totalDuring/60.0];
    NSRange minRange = [rawDurationStr rangeOfString:@" min"];
    NSMutableAttributedString *timeStr = [[NSMutableAttributedString alloc] initWithString:rawDurationStr];
    [timeStr addAttribute:NSForegroundColorAttributeName value:COLOR_STAT_GREEN range:NSMakeRange(0, minRange.location)];
    [timeStr addAttribute:NSFontAttributeName value:DigitalFontSize(20) range:NSMakeRange(0, minRange.location)];
    self.healthCell.tripDurationLabel.attributedText = timeStr;
    
//    NSString * rawStr = [NSString stringWithFormat:@"%.1f km  %.f min", totalDist/1000.0, totalDuring/60.0];
//    NSRange kmRange = [rawStr rangeOfString:@" km "];
//    NSRange minRange = [rawStr rangeOfString:@" min"];
//    NSMutableAttributedString *todayStr = [[NSMutableAttributedString alloc] initWithString:rawStr];
//    [todayStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x7bce33) range:NSMakeRange(0, kmRange.location)];
//    [todayStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x7bce33) range:NSMakeRange(kmRange.location+kmRange.length, minRange.location-(kmRange.location+kmRange.length))];
//    [todayStr addAttribute:NSFontAttributeName value:DigitalFontSize(14) range:NSMakeRange(0, kmRange.location)];
//    [todayStr addAttribute:NSFontAttributeName value:DigitalFontSize(14) range:NSMakeRange(kmRange.location+kmRange.length, minRange.location-(kmRange.location+kmRange.length))];
//    
//    // update illegal
//    UIFont * font12 = [UIFont boldSystemFontOfSize:11];
//    self.healthCell.IllegalCount.attributedText = [NSAttributedString stringWithNumber:@"0" font:DigitalFontSize(14) color:COLOR_STAT_RED andUnit:@" 新违章" font:font12 color:[UIColor whiteColor]];
//    self.healthCell.IllegalPendingCount.attributedText = [NSAttributedString stringWithNumber:@"0" font:DigitalFontSize(14) color:COLOR_STAT_RED andUnit:@" 未处理违章" font:font12 color:[UIColor whiteColor]];
    
    
    // car maintain info and health
    self.healthCell.carMaintainProgress.progressFillColor = COLOR_STAT_RED;
    [self.healthCell updateWithMaintainInfo:self.maintainInfo];
}

- (void) gotoDetail:(ParkingRegion*)region fromLoc:(CLLocation*)curLoc
{
    if (nil == region && nil == self.defaultDest) {
        return;
    }
    
    CTRoute * route = [CTRoute new];
    [route setCoorType:eCoorTypeBaidu];
    route.orig.name = @"当前位置";
    [route.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
    
    if (region) {
        route.dest.name = [region nameWithDefault:@"目的地"];
        [route.dest updateWithCoordinate:[GeoTransformer earth2Baidu:[region centerCoordinate]]];
    } else if (self.defaultDest) {
        route.dest.name = self.defaultDest.name;
        [route.dest updateWithCoordinate:self.defaultDest.pt];
    }
    
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
            self.healthCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeHealthCellIdNew" forIndexPath:indexPath];
            [self updateHealth];
            
            if (self.healthCell.carHealthView.gestureRecognizers.count == 0) {
                UITapGestureRecognizer * gestureHealth = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHealth)];
                [self.healthCell.carHealthView addGestureRecognizer:gestureHealth];
            }
            if (self.healthCell.carMaintainView.gestureRecognizers.count == 0) {
                UITapGestureRecognizer * gestureMaintain = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMaintain)];
                [self.healthCell.carMaintainView addGestureRecognizer:gestureMaintain];
            }
            
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
            return CGSizeMake(320, 170);
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
