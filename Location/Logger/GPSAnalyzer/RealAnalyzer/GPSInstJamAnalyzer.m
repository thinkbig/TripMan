//
//  GPSInstJamAnalyzer.m
//  TripMan
//
//  Created by taq on 3/31/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "GPSInstJamAnalyzer.h"
#import "TSPair.h"
#import "CTInstReportFacade.h"
#import "GPSOffTimeFilter.h"

@interface GPSInstJamAnalyzer ()

@property (nonatomic, strong) GPSLogItem *          lastItem;
@property (nonatomic, strong) GPSLogItem *          lastReportItem;

@property (nonatomic, strong) TSPair *              penddingJam;
@property (nonatomic, strong) NSMutableArray *      trafficJamArr;

@property (nonatomic, strong) CTInstReportModel *   reportModel;

@end

@implementation GPSInstJamAnalyzer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.trafficJamArr = [[NSMutableArray alloc] init];
        self.anaStat = eJamAnalyzeStatNone;
    }
    return self;
}

- (void)appendGPSInfo:(GPSLogItem*)item
{
    BOOL isJam = [self isJamItem:item];
    
    if (self.trafficJamArr.count == 0) {
        if (isJam) {
            self.penddingJam = TSPairMake(item, item, nil);
            [self.trafficJamArr addObject:item];
            self.anaStat = eJamAnalyzeStatPendding;
        }
    } else {
        [self.trafficJamArr addObject:item];
        if (isJam) {
            if ([self isJamItem:self.lastItem]) {
                self.penddingJam.second = item;
            } else {
                GPSLogItem * oneItem = self.penddingJam.second;
                CGFloat jamDist = [oneItem distanceFrom:item];
                CGFloat jamDuring = [item.timestamp timeIntervalSinceDate:oneItem.timestamp];
                
                if (jamDist < 100 || jamDuring < 10) {
                    self.penddingJam.second = item;
                }
            }
        } else {
            GPSLogItem * oneItem = self.penddingJam.second;
            CGFloat jamDist = [oneItem distanceFrom:item];
            CGFloat jamDuring = [item.timestamp timeIntervalSinceDate:oneItem.timestamp];
            
            if (jamDist > 200 && jamDuring > 30) {
                // 判断jam结束了，上报并清除jam缓存
                if (eJamAnalyzeStatConfirmed == self.anaStat) {
                    [self reportJamEnded];
                }
                [self reset];
            }
        }
    }
    
    self.lastItem = item;
    
    eJamAnalyzeStat stat = [self checkJamStat:self.penddingJam];
    if (stat == eJamAnalyzeStatConfirmed) {
        if (eJamAnalyzeStatConfirmed != self.anaStat) {
            [self reportJamStart];
        } else if (self.penddingJam.second) {
            GPSLogItem * lastReportItem = self.penddingJam.second;
            CGFloat jamDist = [lastReportItem distanceFrom:item];
            CGFloat jamDuring = [item.timestamp timeIntervalSinceDate:lastReportItem.timestamp];
            if ((jamDist > 100 && jamDuring > 60*3) || jamDist > 300 || jamDuring > 5*60) {
                [self reportJamResume];
            }
        }
    }
    self.anaStat = stat;
}

- (BOOL) isJamItem:(GPSLogItem*)item
{
    CGFloat curSpeed = ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
    return (curSpeed < cInsTrafficJamSpeed);
}

- (eJamAnalyzeStat) checkJamStat:(TSPair*)jamPair
{
    GPSLogItem * jamStart = jamPair.first;
    GPSLogItem * jamEnd = jamPair.second;
    CGFloat thisDuring = [jamEnd.timestamp timeIntervalSinceDate:jamStart.timestamp];
    
    if (thisDuring > 60*3) {
        return eJamAnalyzeStatConfirmed;
    } else if (thisDuring > 60) {
        return eJamAnalyzeStatMaybe;
    } else if (self.trafficJamArr.count > 0) {
        return eJamAnalyzeStatPendding;
    }
    return eJamAnalyzeStatNone;
}

- (CTInstReportModel*) modelWithStartItem:(GPSLogItem*)item
{
    CTInstReportModel * curModel = [CTInstReportModel new];
    [curModel updateWithStartItem:item];
    [curModel updateWithUserLocation:[self.lastItem coordinate]];
    
    return curModel;
}

- (BOOL) nearParkingLoc:(NSInteger)parkCnt
{
    if (self.lastItem) {
        ParkingRegionDetail * detail = [[AnaDbManager sharedInst] parkingDetailForCoordinate:[self.lastItem coordinate] minDist:500];
        return (detail.parkingCnt < parkCnt);
    }
    return NO;
}

- (void) reportJamStart
{
    DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamStart");
    
    if (![self nearParkingLoc:5]) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamStart canceled");
        return;
    }
    
    CTInstReportModel * curModel = [self modelWithStartItem:self.penddingJam.first];
    self.reportModel = curModel;
    
    CTInstReportFacade * facade = [CTInstReportFacade new];
    facade.reportModel = curModel;
    [facade requestWithSuccess:^(NSDictionary * dict) {
        NSString * jamId = dict[@"jam_id"];
        curModel.jam_id = jamId;
        self.lastReportItem = self.penddingJam.first;
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamStart Success");
    } failure:^(NSError * err) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamStart Fail: %@", err);
    }];
}

- (void) reportJamResume
{
    DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamResume");
    
    if (![self nearParkingLoc:5]) {
        [self reportJamIgnore];
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamResume canceled");
        return;
    }
    
    if (nil == self.reportModel) {
        self.reportModel = [self modelWithStartItem:self.penddingJam.first];
    }
    GPSLogItem * reportItem = self.lastItem;
    [self.reportModel updateWithUserLocation:[self.lastItem coordinate]];
    
    CTInstReportFacade * facade = [CTInstReportFacade new];
    facade.reportModel = self.reportModel;
    [facade requestWithSuccess:^(NSDictionary * dict) {
        self.lastReportItem = reportItem;
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamResume Success");
    } failure:^(NSError * err) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamResume Fail: %@", err);
    }];
}

- (void) reportJamEnded
{
    DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded");
    
    if (![self nearParkingLoc:5]) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded canceled");
        [self reportJamIgnore];
        return;
    }
    
    TSPair * pair = self.penddingJam;
    NSArray * jamArr = [self.trafficJamArr copy];
    NSArray * waypoint = [GPSOffTimeFilter keyRouteFromGPS:jamArr autoFilter:YES];
    NSString * wayptStr = [GPSOffTimeFilter routeToString:waypoint withTimeStamp:YES];
    
    if (nil == self.reportModel) {
        self.reportModel = [self modelWithStartItem:pair.first];
    }
    [self.reportModel updateWithUserLocation:[self.lastItem coordinate]];
    [self.reportModel updateWithEndItem:pair.second];
    self.reportModel.waypoints = wayptStr;
    
    CTInstReportModel * curModel = self.reportModel;
    CTInstReportFacade * facade = [CTInstReportFacade new];
    facade.reportModel = curModel;
    facade.retryCnt = 1;
    [facade requestWithSuccess:^(NSDictionary * dict) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded Success");
    } failure:^(NSError * err) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded Fail");
    }];
    
    [self reset];
}

- (void) reportJamIgnore
{
    if (nil == self.reportModel.jam_id) {
        return;
    }
    DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamIgnore");
    
    CTInstReportModel * curModel = [CTInstReportModel new];
    curModel.jam_id = self.reportModel.jam_id;
    CTInstReportFacade * facade = [CTInstReportFacade new];
    facade.reportModel = curModel;
    facade.ignore = YES;
    [facade requestWithSuccess:^(NSDictionary * dict) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded Success");
    } failure:^(NSError * err) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded Fail");
    }];
    
    [self reset];
}

- (void) reset
{
    self.penddingJam = nil;
    [self.trafficJamArr removeAllObjects];
    self.reportModel = nil;
    self.lastReportItem = nil;
}

- (void) driveEndAt:(GPSLogItem*)item
{
    // 说明程序判断驾驶停止，但是reportJamEnded并没有上报，因此丢弃
    if (self.reportModel.jam_id && self.reportModel.st_date) {
        [self reportJamIgnore];
    } else {
        [self reset];
    }
}

@end
