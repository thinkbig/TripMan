//
//  LocationViewController.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "LocationViewController.h"
#import "GPSLogger.h"
#import "DataReporter.h"
#import "JamDisplayViewController.h"
#import "LogFileListViewController.h"
#import "DebugTableCell.h"

typedef NS_ENUM(NSUInteger, eDebugDisplayType) {
    eDebugDisplayUid = 0,
    eDebugDisplayUdid,
    eDebugDisplayServerUrl,
    eDebugDisplayNerwork,
    eDebugDisplayReportStat,
    eDebugDisplayCount
};

typedef NS_ENUM(NSUInteger, eDebugActionType) {
    eDebugActionShowLog = 0,
    eDebugActionJamsMap,
    eDebugActionUpdatePOIName,
    eDebugActionRevertDelete,
    eDebugActionAnalyzeAllTrip,
    eDebugActionForceUpload,
    eDebugActionShowDebugInfo,
    eDebugActionCount
};

@implementation LocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)closeDebug:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchChanged:(UISwitch*)cellSwitch
{
    [[NSUserDefaults standardUserDefaults] setObject:@(cellSwitch.isOn) forKey:kDebugEnable];
}


#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (0 == section) {
        return eDebugDisplayCount;
    } else if (1 == section) {
        return eDebugActionCount;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (0 == section) {
        return @"调试信息";
    } else if (1 == section) {
        return @"调试方法";
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;
    if (0 == indexPath.section) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"DebugDetailCellId"];
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (eDebugDisplayUid == indexPath.row) {
            cell.textLabel.text = @"用户id";
            cell.detailTextLabel.text = [[GToolUtil sharedInstance] userId];
        } else if (eDebugDisplayUdid == indexPath.row) {
            cell.textLabel.text = @"设备id";
            cell.detailTextLabel.text = [[GToolUtil sharedInstance] deviceId];
        } else if (eDebugDisplayServerUrl == indexPath.row) {
            cell.textLabel.text = @"服务器url";
            cell.detailTextLabel.text = kChetuBaseUrl;
        } else if (eDebugDisplayNerwork == indexPath.row) {
            cell.textLabel.text = @"网络环境";
            if (IS_REACHABLE) {
                if (IS_WIFI) {
                    cell.detailTextLabel.text = @"wifi";
                } else {
                    cell.detailTextLabel.text = @"蜂窝网络";
                }
            } else {
                cell.detailTextLabel.text = @"网络不可用";
            }
        }  else if (eDebugDisplayReportStat == indexPath.row) {
            cell.textLabel.text = @"待上报旅程";
            TripsCoreDataManager * manager = [AnaDbManager deviceDb];
            NSString * report = [NSString stringWithFormat:@"停车位置(%ld)  旅程详情(%ld)  原始gps(%ld)", (unsigned long)[manager parkingRegionsToReport:NO].count, (unsigned long)[manager tripsReadyToReport:NO].count, (unsigned long)[manager tripRawsReadyToReport].count];
            cell.detailTextLabel.text = report;
        }
    } else if (1 == indexPath.section) {
        if (eDebugActionShowLog == indexPath.row) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"DebugDetailCellId"];
            cell.textLabel.text = @"查看log";
            cell.detailTextLabel.text = @"文件log";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (eDebugActionJamsMap == indexPath.row) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"DebugDetailCellId"];
            cell.textLabel.text = @"查看实时拥堵地图";
            cell.detailTextLabel.text = @"显示8小时内的拥堵数据";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }  else if (eDebugActionUpdatePOIName == indexPath.row) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"DebugDetailCellId"];
            cell.textLabel.text = @"更新停车地点的名称";
            cell.detailTextLabel.text = @"调用百度接口重新获取POI名称，手动修改过的名字会保留";
        } else if (eDebugActionRevertDelete == indexPath.row) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"DebugDetailCellId"];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"恢复所有删除的旅程";
            cell.detailTextLabel.text = @"恢复用户手工删除的本地旅程";
        } else if (eDebugActionAnalyzeAllTrip == indexPath.row) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"DebugDetailCellId"];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"更新本地数据库";
            cell.detailTextLabel.text = @"当旅程的分析算法有变化时，点击可以重新计算";
        } else if (eDebugActionForceUpload == indexPath.row) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"DebugDetailCellId"];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"强制同步";
            cell.detailTextLabel.text = @"强行上报所有数据到当前服务器，点击的时候，请非常清楚自己在做什么";
        } else if (eDebugActionShowDebugInfo == indexPath.row) {
            DebugTableCell * realCell = [tableView dequeueReusableCellWithIdentifier:@"DebugTableCellId"];
            realCell.mainLabel.text = @"打开调试模式";
            NSNumber * enable = [[NSUserDefaults standardUserDefaults] objectForKey:kDebugEnable];
            if (enable && [enable boolValue]) {
                realCell.cellSwitch.on = YES;
            } else {
                realCell.cellSwitch.on = NO;
            }
            [realCell.cellSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            realCell.cellSwitch.tag = indexPath.section * 100 + indexPath.row;
            cell = realCell;
        }
    }
    cell.tag = indexPath.section * 100 + indexPath.row;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        return 54;
    } else if (1 == indexPath.section) {
        if (eDebugActionShowDebugInfo == indexPath.row) {
            return 50;
        }
        return 64;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (0 == indexPath.section) {
        UITableViewCell * cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = cell.detailTextLabel.text;
        [self showToast:[NSString stringWithFormat:@"%@ 已经拷贝到剪切板", cell.textLabel.text] onDismiss:nil];
    } else if (1 == indexPath.section) {
        if (eDebugActionShowLog == indexPath.row) {
            LogFileListViewController * logListVC = [self.storyboard instantiateViewControllerWithIdentifier:@"LogDisplayList"];
            [self.navigationController pushViewController:logListVC animated:YES];
        } else if (eDebugActionJamsMap == indexPath.row) {
            JamDisplayViewController * jamVC = [self.storyboard instantiateViewControllerWithIdentifier:@"JamDisplayVC"];
            [self.navigationController pushViewController:jamVC animated:YES];
        } else if (eDebugActionUpdatePOIName == indexPath.row) {
            [[BussinessDataProvider sharedInstance] updateAllRegionInfo:YES];
        } else if (eDebugActionRevertDelete == indexPath.row) {
            NSArray * arr = [TripSummary where:@"is_valid=0" inContext:[AnaDbManager deviceDb].tripAnalyzerContent];
            for (TripSummary * sum in arr) {
                sum.is_valid = @YES;
            }
            [[AnaDbManager sharedInst] commit];
            [self showToast:@"恢复完成！" onDismiss:nil];
        } else if (eDebugActionAnalyzeAllTrip == indexPath.row) {
            [self showLoading];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [[GPSLogger sharedLogger].offTimeAnalyzer analyzeAllFinishedTrip:YES];
                [self hideLoading];
            });
        } else if (eDebugActionForceUpload == indexPath.row) {
            [[DataReporter sharedInst] forceAsync];
        }
    }
}

@end
