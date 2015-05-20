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
#import "BaiduMapViewController.h"
#import "ParkingRegion+Fetcher.h"
#import "UIAlertView+RZCompletionBlocks.h"
#import "GPSInstJamAnalyzer.h"
#import "TripSummary+Fetcher.h"
#import "ActionSheetStringPicker.h"
#import "TripSimulator.h"
#import "CTConfigProvider.h"

@interface TicketDetailViewController () <EMHintDelegate> {
    BOOL        _mayEditName;
}

@property (nonatomic, strong) NSArray *             speedSegs;
@property (nonatomic, strong) AddressEditCell *     editCell;

@property (nonatomic, strong) EMHint *              hintView;

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
    
    _mayEditName = NO;
    
    if ([GToolUtil isEnableDebug]) {
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSecret)];
        tapGesture.numberOfTapsRequired = 2;
        [self.navigationController.navigationBar addGestureRecognizer:tapGesture];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showHintIfNeeded];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.hintView clear];
    [super viewWillDisappear:animated];
}

- (void) tapSecret{
    NSString * tripStr = [CommonFacade toJsonString:[self.tripSum toJsonDict] prettyPrint:NO];
    NSString * stLocStr = [CommonFacade toJsonString:[self.tripSum.region_group.start_region toJsonDict] prettyPrint:NO];
    NSString * edLocStr = [CommonFacade toJsonString:[self.tripSum.region_group.end_region toJsonDict] prettyPrint:NO];
    if (nil == tripStr) {
        [self showToast:@"该车票还没有上传，因此无法获得车票id，请等待上传结束后再试试" onDismiss:nil];
        return;
    }
    
    [ActionSheetStringPicker showPickerWithTitle:@"选择内容复制到剪切板" rows:@[@"车票Id", @"出发地点Id", @"到达地点Id", @"车票详情Json数据", @"出发地点Json数据", @"到达地点Json数据"] initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        if (0 == selectedIndex) {
            pasteboard.string = self.tripSum.trip_id;
        } else if (1 == selectedIndex) {
            pasteboard.string = self.tripSum.region_group.start_region.parking_id;
        } else if (2 == selectedIndex) {
            pasteboard.string = self.tripSum.region_group.end_region.parking_id;
        } else if (3 == selectedIndex) {
            pasteboard.string = tripStr;
        } else if (4 == selectedIndex) {
            pasteboard.string = stLocStr;
        } else if (5 == selectedIndex) {
            pasteboard.string = edLocStr;
        }
        [self showToast:[NSString stringWithFormat:@"%@ 已经拷贝到剪切板", selectedValue] onDismiss:nil];
    } cancelBlock:nil origin:self.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTripSum:(TripSummary *)tripSum
{
    //[[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:tripSum withAnalyzer:nil];
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

- (BOOL)addressModified
{
    NSString * newUserSt = self.editCell.stAddress.text;
    NSString * newUsered = self.editCell.edAddress.text;
    if ((![newUserSt isEqualToString:_tripSum.region_group.start_region.nearby_poi]) &&
        (![newUserSt isEqualToString:_tripSum.region_group.start_region.user_mark]) &&
        (![newUserSt isEqualToString:@"未知地点"])) {
        return YES;
    }
    if ((![newUsered isEqualToString:_tripSum.region_group.end_region.nearby_poi]) &&
        (![newUsered isEqualToString:_tripSum.region_group.end_region.user_mark]) &&
        (![newUsered isEqualToString:@"未知地点"])) {
        return YES;
    }
    return NO;
}

- (void)saveNewUserMark
{
    NSString * newUserSt = self.editCell.stAddress.text;
    NSString * newUsered = self.editCell.edAddress.text;
    if ((![newUserSt isEqualToString:_tripSum.region_group.start_region.nearby_poi]) &&
        (![newUserSt isEqualToString:_tripSum.region_group.start_region.user_mark]) &&
        (![newUserSt isEqualToString:@"未知地点"])) {
        _tripSum.region_group.start_region.user_mark = newUserSt;
    }
    if ((![newUsered isEqualToString:_tripSum.region_group.end_region.nearby_poi]) &&
        (![newUsered isEqualToString:_tripSum.region_group.end_region.user_mark]) &&
        (![newUsered isEqualToString:@"未知地点"])) {
        _tripSum.region_group.end_region.user_mark = newUsered;
    }
    
    [_tripSum save];
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    } completion:^(BOOL finished) {
        [self showToast:@"保存成功" onDismiss:nil];
        self.saveBtn.enabled = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyTripModify object:nil];
    }];
}

- (IBAction)saveAddress:(id)sender {
    [self.collectionView endEditing:YES];
    [self saveNewUserMark];
}

- (IBAction)goBack:(id)sender {
    [self.collectionView endEditing:YES];
    if (_mayEditName && [self addressModified]) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"是否保存" message:@"修改的地址信息还没有保存，是否保存？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"保存", @"不保存退出", nil];
        [alert rz_showWithCompletionBlock:^(NSInteger dismissalButtonIndex) {
            if (1 == dismissalButtonIndex) {
                [self saveNewUserMark];
            } else if (2 == dismissalButtonIndex) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) textFieldDidChange:(UITextField*) textField {
    _mayEditName = YES;
    BOOL isSameLoc = NO;
    if (_tripSum.region_group.start_region && _tripSum.region_group.start_region == _tripSum.region_group.end_region) {
        isSameLoc = YES;
    }
    if (ST_ADDRESS_TAG == textField.tag) {
        if (isSameLoc) {
            self.editCell.edAddress.text = textField.text;
        }
    } else if (ED_ADDRESS_TAG == textField.tag) {
        if (isSameLoc) {
            self.editCell.stAddress.text = textField.text;
        }
    }
    self.saveBtn.enabled = [self addressModified];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)deleteTrip
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"是否删除？" message:@"删除后，这条旅程将无法找回" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"删除", nil];
    [alert rz_showWithCompletionBlock:^(NSInteger dismissalButtonIndex) {
        if (1 == dismissalButtonIndex) {
            self.tripSum.is_valid = @NO;
            [[AnaDbManager sharedInst] commit];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyTripModify object:nil];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
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
    return 7;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (0 == indexPath.row) {
        if (nil == self.editCell) {
            self.editCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddressEditCellId" forIndexPath:indexPath];
            [self.editCell.stAddress addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [self.editCell.edAddress addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }
        self.editCell.stAddress.text = [_tripSum.region_group.start_region nameWithDefault:@"未知地点"];
        self.editCell.edAddress.text = [_tripSum.region_group.end_region nameWithDefault:@"未知地点"];
        cell = self.editCell;
    } else if (1 == indexPath.row) {
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
    } else if (2 == indexPath.row) {
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
    } else if (3 == indexPath.row) {
        TicketJamDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JamDetailCell" forIndexPath:indexPath];
        realCell.cellTitle.text = @"红绿灯数据";
        [realCell setLabel11Str:@"通过红绿灯数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.traffic_light_tol_cnt integerValue]] andUnit:@"个"];
        [realCell setLabel21Str:@"等待个数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.traffic_light_jam_cnt floatValue]] andUnit:@"个"];
        [realCell setLabel22Str:@"等待耗时" withValue:[NSString stringWithFormat:@"%.f", (long)[_tripSum.traffic_light_waiting floatValue]/60.0] andUnit:@"min"];
        [realCell setLabel23Str:@"单次最长等待" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.traffic_jam_max_during floatValue]/60.0] andUnit:@"min"];
        
        cell = realCell;
    } else if (4 == indexPath.row) {
        TicketDriveDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TicketDriveDetailCellId" forIndexPath:indexPath];
        realCell.cellTitle.text = @"转弯数据";
        
        [realCell setLabel11Str:@"右转弯次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.turning_info.right_turn_cnt integerValue]] andUnit:@"个"];
        [realCell setLabel12Str:@"平均速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.turning_info.right_turn_avg_speed floatValue]*3.6] andUnit:@"km/h"];
        [realCell setLabel13Str:@"最大速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.turning_info.right_turn_max_speed floatValue]*3.6] andUnit:@"km/h"];
        
        [realCell setLabel21Str:@"左转弯次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.turning_info.left_turn_cnt integerValue]] andUnit:@"个"];
        [realCell setLabel22Str:@"平均速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.turning_info.left_turn_avg_speed floatValue]*3.6] andUnit:@"km/h"];
        [realCell setLabel23Str:@"最大速度" withValue:[NSString stringWithFormat:@"%.1f", [_tripSum.turning_info.left_turn_max_speed floatValue]*3.6] andUnit:@"km/h"];
        
        cell = realCell;
    } else if (5 == indexPath.row) {
        TicketDriveDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TicketDriveDetailCellId" forIndexPath:indexPath];
        realCell.cellTitle.text = @"加速减速";
        
        [realCell setLabel11Str:@"加速次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.driving_info.acce_cnt integerValue]] andUnit:@"次"];
        [realCell setLabel12Str:@"深度加速次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.driving_info.hard_acce_cnt integerValue]] andUnit:@"次"];
        [realCell setLabel13Str:@"5秒最大加速" withValue:[NSString stringWithFormat:@"%.1f", 3.6*([_tripSum.driving_info.max_acce_end_speed floatValue] - [_tripSum.driving_info.max_acce_begin_speed floatValue])] andUnit:@"km/h"];
        
        [realCell setLabel21Str:@"刹车次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.driving_info.acce_cnt integerValue]] andUnit:@"次"];
        [realCell setLabel22Str:@"深度刹车次数" withValue:[NSString stringWithFormat:@"%ld", (long)[_tripSum.driving_info.hard_breaking_cnt integerValue]] andUnit:@"次"];
        [realCell setLabel23Str:@"5秒最大减速" withValue:[NSString stringWithFormat:@"%.1f", -3.6*([_tripSum.driving_info.max_breaking_end_speed floatValue] - [_tripSum.driving_info.max_breaking_begin_speed floatValue])] andUnit:@"km/h"];
        
        cell = realCell;
    } else if (6 == indexPath.row) {
        TripDeleteCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TripDeleteCellId" forIndexPath:indexPath];
        [realCell.deleteBtn addTarget:self action:@selector(deleteTrip) forControlEvents:UIControlEventTouchUpInside];
        cell = realCell;
    }
    if (0 == indexPath.row || indexPath.row % 2 == 1) {
        cell.backgroundColor = [UIColor clearColor];
    } else {
        cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.row) {
        return CGSizeMake(320.f, 75.f);
    } else if (1 == indexPath.row) {
        return CGSizeMake(320.f, 200.f);
    } else if (indexPath.row >= 2 && indexPath.row <= 5) {
        return CGSizeMake(320.f, 150.f);
    } else if (6 == indexPath.row) {
        return CGSizeMake(320.f, 60.f);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (1 == indexPath.row) {
        BaiduMapViewController * mapVC = [self.storyboard instantiateViewControllerWithIdentifier:@"baiduMapVC"];
        mapVC.tripSum = self.tripSum;
        [self.navigationController pushViewController:mapVC animated:YES];
    }
    if ([GToolUtil isEnableDebug]) {
        if (2 == indexPath.row) {
            NSArray * logArr = [[GPSLogger sharedLogger].dbLogger selectLogFrom:self.tripSum.start_date toDate:self.tripSum.end_date offset:0 limit:0];
            GPSInstJamAnalyzer * ana = [GPSInstJamAnalyzer new];
            for (GPSLogItem * item in logArr) {
                [ana appendGPSInfo:item];
            }
        } else if (3 == indexPath.row) {
            NSArray * pts = nil;
            NSData * ptsData = self.tripSum.turning_info.addi_data;
            if (ptsData) {
                pts = [NSKeyedUnarchiver unarchiveObjectWithData:ptsData];
            }
            [[BussinessDataProvider sharedInstance] updateRoadMarkForTrips:self.tripSum ofTurningPoints:pts success:^(id cnt) {
                NSLog(@"traffic light cnt = %@", cnt);
            } failure:nil];
        } else if (4 == indexPath.row) {
            
//            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//            [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
//            NSDate * origDate= [dateFormatter dateFromString:@"2015-05-16 20:16:22"];
//            NSDate * destDate= [dateFormatter dateFromString:@"2015-05-16 21:05:20"];
//            
//            GPSFMDBLogger * loggerDB = [GPSLogger sharedLogger].dbLogger;
//            NSArray * logArr = [loggerDB selectLogFrom:origDate toDate:destDate offset:0 limit:0];
//            TripSimulator * simulator = [TripSimulator new];
//            simulator.gpsLogs = logArr;
            
              GPSFMDBLogger * loggerDB = [GPSLogger sharedLogger].dbLogger;
              NSArray * logArr = [loggerDB selectLogFrom:[self.tripSum.start_date dateByAddingTimeInterval:-180] toDate:[self.tripSum.end_date dateByAddingTimeInterval:60*10] offset:0 limit:0];
              TripSimulator * simulator = [TripSimulator new];
              simulator.gpsLogs = logArr;
        }  else if (5 == indexPath.row) {
            NSLog(@"is valid = %d", [[GPSLogger sharedLogger].offTimeAnalyzer checkValid:self.tripSum]);
        }
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
{
    [scrollView endEditing:YES];
}

#pragma EMHintDelegate

- (void) showHintIfNeeded
{
    NSString * showId = nil;
    if (![[CTConfigProvider sharedInstance] hasShowHintForKey:eShowHintMyTripEditAddress]) {
        showId = @"hintSwipe";
    }
    
    if (showId) {
        if (nil == self.hintView) {
            self.hintView = [[EMHint alloc] init];
            [self.hintView setHintDelegate:self];
        }
        self.hintView.customId = showId;
        self.hintView.bgColor = [UIColor colorWithWhite:0 alpha:0.75];
        [self.hintView presentModalMessage:@"" where:self.view.window];
    }
}

- (NSArray*) hintStateRectsToHint:(EMHint*)hintState
{
    CGPoint pos = self.editCell.frame.origin;
    pos.x += 50;
    CGPoint newPos = [self.view.window convertPoint:pos fromView:self.editCell.superview];
    return @[[NSValue valueWithCGRect:CGRectMake(newPos.x, newPos.y, 60, self.editCell.frame.size.height)]];
}

- (UIView*) hintStateViewForDialog:(EMHint*)hintState
{
    UILabel * hintLabel = [EMHint defaultLabelWithText:@"点击可以修改备注\r如：公司，我家"];
    CGPoint center = self.view.center;
    hintLabel.center = CGPointMake(center.x, center.y);
    
    return hintLabel;
}

@end
