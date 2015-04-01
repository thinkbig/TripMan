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

@property (nonatomic, strong) TSPair *              penddingJam;
@property (nonatomic, strong) NSMutableArray *      trafficJamArr;

@property (nonatomic, strong) CTInstReportModel *   reportModel;      // TSPair(model, retryCnt)

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
            
            if (jamDist > 100 && jamDuring > 10) {
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
    if (eJamAnalyzeStatConfirmed != self.anaStat && stat == eJamAnalyzeStatConfirmed) {
        [self reportJamStart];
    }
    self.anaStat = stat;
}

- (BOOL) isJamItem:(GPSLogItem*)item
{
    CGFloat curSpeed = ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
    return (curSpeed < cAvgTrafficJamSpeed);
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

- (BOOL) shouldReport
{
    if (self.lastItem) {
        ParkingRegionDetail * detail = [[AnaDbManager sharedInst] parkingDetailForCoordinate:[self.lastItem coordinate] minDist:500];
        return (detail.parkingCnt < 5);
    }
    return NO;
}

- (void) reportJamStart
{
    DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamStart");
    
    if (![self shouldReport]) {
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
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamStart Success");
    } failure:^(NSError * err) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamStart Fail: %@", err);
    }];
}

- (void) reportJamEnded
{
    DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded");
    
    if (![self shouldReport]) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded canceled");
        return;
    }
    
    TSPair * pair = self.penddingJam;
    NSArray * jamArr = [self.trafficJamArr copy];
    NSArray * waypoint = [GPSOffTimeFilter keyRouteFromGPS:jamArr];
    NSString * wayptStr = [GPSOffTimeFilter routeToString:waypoint];
    
    if (nil == self.reportModel) {
        self.reportModel = [self modelWithStartItem:pair.first];
    }
    [self.reportModel updateWithUserLocation:[self.lastItem coordinate]];
    [self.reportModel updateWithEndItem:pair.second];
    self.reportModel.waypoints = wayptStr;
    
    CTInstReportModel * curModel = self.reportModel;
    CTInstReportFacade * facade = [CTInstReportFacade new];
    facade.reportModel = curModel;
    [facade requestWithSuccess:^(NSDictionary * dict) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded Success");
        if (curModel == self.reportModel) {
            self.reportModel = nil;
        };
    } failure:^(NSError * err) {
        DDLogWarn(@"&&&&&&&&&&&&&&&&&&& reportJamEnded Fail: %@", err);
    }];
}

- (void) reset
{
    self.penddingJam = nil;
    [self.trafficJamArr removeAllObjects];
}

@end
