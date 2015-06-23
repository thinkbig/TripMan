//
//  DataReporter.m
//  TripMan
//
//  Created by taq on 3/2/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "DataReporter.h"
#import "CTWakeupFacade.h"
#import "CTLocReportFacade.h"
#import "CTTripReportFacade.h"
#import "CTTripRawReportFacade.h"
#import "NSDate+Utilities.h"
#import "UIAlertView+RZCompletionBlocks.h"

#define BG_ASYNC_DURING                 29

typedef NS_ENUM(NSUInteger, eReportType) {
    eReportTypeLocation = 1,
    eReportTypeTripDetail = 2,
    eReportTypeTripRaw = 3,
};

@interface ReportTask : NSObject

@property (nonatomic)           eReportType     type;
@property (nonatomic, strong)   NSArray *       items;

- (id) initWithType:(eReportType)type andItems:(NSArray*)items;

@end

@implementation ReportTask

- (id) initWithType:(eReportType)type andItems:(NSArray*)items {
    self = [super init];
    if (self) {
        self.type = type;
        self.items = items;
    }
    return self;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////

@interface DataReporter () {
    
    BOOL _asyncingDeviceInfo;
    BOOL _asyncingReport;
    
    NSUInteger _tolLocAyncCnt;
    NSUInteger _tolTripAyncCnt;
    NSUInteger _tolTripRawAyncCnt;
}

@property (nonatomic, strong)   NSTimer *               restartTimer;
@property (nonatomic, strong)   NSMutableArray *        pendingLocation;
@property (nonatomic, strong)   NSMutableArray *        pendingTripsDetail;
@property (nonatomic, strong)   NSMutableArray *        pendingTripsRaw;

@property (nonatomic, strong)   NSDate *                asyncBefore;        // 设置一个时间阈值，超过这个时间，则停止同步
@property (nonatomic, copy)     ReportCompleteBlock     bgFetchBlock;

@property (nonatomic)           NSInteger               finishCnt;
@property (nonatomic)           NSInteger               tolCnt;
@property (nonatomic)           BOOL                    forceAsyncAll;      // 强制同步所有数据（会有一个模态的进度条）

@end

@implementation DataReporter

+ (instancetype)sharedInst {
    static DataReporter *_sharedInst = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInst = [[self alloc] init];
    });
    
    return _sharedInst;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tolLocAyncCnt = 1;
        _tolTripAyncCnt = 1;
        _tolTripRawAyncCnt = 1;
        _asyncingDeviceInfo = NO;
        _asyncingReport = NO;
        self.asyncBefore = [NSDate distantFuture];
        self.onlyWifiReport = YES;
        self.forceAsyncAll = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) applicationEnterBackground {
    self.forceAsyncAll = NO;
    self.asyncBefore = [NSDate dateWithTimeIntervalSinceNow:BG_ASYNC_DURING];
}

- (void) applicationDidBecomeActive {
    self.asyncBefore = [NSDate distantFuture];
}

- (void) asyncUserDeviceInfo
{
    if (!_asyncingDeviceInfo) {
        _asyncingDeviceInfo = YES;
        CTWakeupFacade * facade = [[CTWakeupFacade alloc] init];
        [facade requestWithSuccess:^(id result) {
            _asyncingDeviceInfo = NO;
            NSLog(@"asyncUserDeviceInfo result = %@", result);
        } failure:^(NSError * err) {
            _asyncingDeviceInfo = NO;
            NSLog(@"asyncUserDeviceInfo err = %@", err);
        }];
    }
}

- (void)forceAsync
{
    [[GToolUtil sharedInstance] showPieHUDWithText:@"同步中..." andProgress:0];
    
    // check location reporter task
    NSArray * newLoc = [[AnaDbManager deviceDb] parkingRegionsToReport:YES];
    if (newLoc.count > 0) {
        self.pendingLocation = [NSMutableArray arrayWithArray:newLoc];
    }
    
    // check trip detail reporter task
    NSArray * newTrip = [[AnaDbManager deviceDb] tripsReadyToReport:YES];
    if (newTrip.count > 0) {
        self.pendingTripsDetail = [NSMutableArray arrayWithArray:newTrip];
        self.pendingTripsRaw = [NSMutableArray arrayWithArray:newTrip];
    }
    self.finishCnt = 0;
    self.tolCnt = newLoc.count + newTrip.count*2;
    
    self.forceAsyncAll = YES;
    [self runBackgroundTask:0];
}

- (void)aliveAsync
{
    [self runBackgroundTask:3];
}

- (void)asyncFromBackgroundFetch:(ReportCompleteBlock)block
{
    self.bgFetchBlock = block;
    self.asyncBefore = [NSDate dateWithTimeIntervalSinceNow:BG_ASYNC_DURING];
    
    [self runBackgroundTask:0];
}

- (void) __setRportResult:(eReportReslut)result {
    if (self.bgFetchBlock) {
        self.bgFetchBlock(result);
        self.bgFetchBlock = nil;
    }
}

- (void)runBackgroundTask: (int)time
{
    [self.restartTimer invalidate];
    
    //check if application is in background mode
    UIApplication * app = [UIApplication sharedApplication];
    if (app.applicationState == UIApplicationStateBackground) {
        __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    }

    self.restartTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(__autoAsync) userInfo:nil repeats:NO];
}

- (void) __autoAsync
{
    if (_asyncingReport) {
        return;
    } else if ((self.onlyWifiReport && !IS_WIFI) || [[NSDate date] isLaterThanDate:self.asyncBefore]) {
        [self __setRportResult:eReportReslutHalt];
        if (self.forceAsyncAll) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[GToolUtil sharedInstance] showPieHUDWithText:@"同步中断（可能不在wifi下）" andProgress:100];
            });
            self.forceAsyncAll = NO;
        }
        return;
    }
    _asyncingReport = YES;
    ReportTask * task = [self __getTask:4];
    if (nil == task) {
        _asyncingReport = NO;
        [self __setRportResult:eReportReslutComplete];
        if (self.forceAsyncAll) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[GToolUtil sharedInstance] showPieHUDWithText:@"同步完成" andProgress:100];
            });
            self.forceAsyncAll = NO;
        }
        return;
    }
    
    // 每个task包含N个同步项，全部完成后，再次检查状态（是否仍然在wifi下，是否超过了同步允许时间），满足条件，则进行下一轮同步
    
    NSArray * items = task.items;
    NSInteger tolCnt = items.count;
    NSMutableArray * completeItems = [NSMutableArray arrayWithCapacity:8];
    
    dispatch_queue_t concurrent_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t downloadGroup = dispatch_group_create();
    for (id item in items)
    {
        if (eReportTypeLocation == task.type)
        {
            ParkingRegion * region = (ParkingRegion*)item;
            CTLocReportFacade * facade = [[CTLocReportFacade alloc] init];
            facade.aimRegion = region;
            dispatch_group_enter(downloadGroup);
            [facade requestWithSuccess:^(NSDictionary * data) {
                NSString * pid = data[@"pid"];
                BOOL success = NO;
                if ([pid isKindOfClass:[NSString class]] && pid.length > 0) {
                    success = YES;
                    region.parking_id = pid;
                    region.is_uploaded = region.is_analyzed;    // 表示地址poi信息是否上传
                } else {
                    NSLog(@"fail reporting location");
                }
                if (success) {
                    dispatch_barrier_async(concurrent_queue, ^{
                        [completeItems addObject:item];
                        dispatch_group_leave(downloadGroup);
                    });
                } else {
                    dispatch_group_leave(downloadGroup);
                }
            } failure:^(NSError * err) {
                NSLog(@"fail reporting location");
                dispatch_group_leave(downloadGroup);
            }];
        }
        else if (eReportTypeTripDetail == task.type)
        {
            TripSummary * sum = (TripSummary*)item;
            CTTripReportFacade * facade = [[CTTripReportFacade alloc] init];
            facade.sum = sum;
            dispatch_group_enter(downloadGroup);
            [facade requestWithSuccess:^(NSDictionary * data) {
                NSString * tid = data[@"tid"];
                BOOL hasRaw = [data[@"has_raw"] boolValue];
                BOOL success = NO;
                if ([tid isKindOfClass:[NSString class]] && tid.length > 0) {
                    success = YES;
                    sum.trip_id = tid;
                    sum.is_uploaded = @(hasRaw);       // 表示原始gps数据是否上传
                } else {
                    NSLog(@"fail reporting trips");
                }
                if (success) {
                    dispatch_barrier_async(concurrent_queue, ^{
                        [completeItems addObject:item];
                        dispatch_group_leave(downloadGroup);
                    });
                } else {
                    dispatch_group_leave(downloadGroup);
                }
            } failure:^(NSError * err) {
                NSLog(@"fail reporting trips");
                dispatch_group_leave(downloadGroup);
            }];
        }
        else if (eReportTypeTripRaw == task.type)
        {
            TripSummary * sum = (TripSummary*)item;
            CTTripRawReportFacade * facade = [[CTTripRawReportFacade alloc] init];
            facade.sum = sum;
            dispatch_group_enter(downloadGroup);
            [facade requestWithSuccess:^(NSDictionary * data) {
                sum.is_uploaded = @(YES);
                dispatch_barrier_async(concurrent_queue, ^{
                    [completeItems addObject:item];
                    dispatch_group_leave(downloadGroup);
                });
                
            } failure:^(NSError * err) {
                NSLog(@"fail reporting trip raw");
                dispatch_group_leave(downloadGroup);
            }];
        }
    }
    
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        [[AnaDbManager deviceDb] commit];
        if (tolCnt > 1 && 0 == completeItems.count) {
            // all report failed
            [self __setRportResult:eReportReslutFail];
            _asyncingReport = NO;
            if (self.forceAsyncAll && self.tolCnt > 0) {
                NSLog(@"fail reporting and choose retry");
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"同步出错" message:@"是否继续" delegate:nil cancelButtonTitle:@"否" otherButtonTitles:@"继续", nil];
                [alert rz_showWithCompletionBlock:^(NSInteger dismissalButtonIndex) {
                    if (0 == dismissalButtonIndex) {
                        self.forceAsyncAll = NO;
                        [[GToolUtil sharedInstance] showPieHUDWithText:@"同步出错" andProgress:100];
                    } else {
                        [self runBackgroundTask:0];
                    }
                }];
            }
            return;
        }
        for (id item in completeItems) {
            if (eReportTypeLocation == task.type) {
                [self.pendingLocation removeObject:item];
            } else if (eReportTypeTripDetail == task.type) {
                [self.pendingTripsDetail removeObject:item];
            } else if (eReportTypeTripRaw == task.type) {
                [self.pendingTripsRaw removeObject:item];
            }
        }
        
        _asyncingReport = NO;
        
        if (self.forceAsyncAll && self.tolCnt > 0) {
            self.finishCnt += completeItems.count;
            CGFloat progress = MAX(1, (100.0*self.finishCnt/self.tolCnt));
            [[GToolUtil sharedInstance] showPieHUDWithText:@"同步中..." andProgress:progress];
        }
        
        [self runBackgroundTask:0];
    });
}

- (ReportTask*) __getTask:(NSUInteger)parallel
{
    if (parallel <= 0) {
        parallel = 1;
    } else if (parallel > 5) {
        parallel = 5;
    }
    
    // check location reporter task
    if (0 == self.pendingLocation.count && !self.forceAsyncAll) {
        NSArray * newLoc = [[AnaDbManager deviceDb] parkingRegionsToReport:NO];
        if (newLoc.count > 0) {
            self.pendingLocation = [NSMutableArray arrayWithArray:newLoc];
            _tolLocAyncCnt = newLoc.count;
        }
    }
    if (self.pendingLocation.count > 0) {
        NSInteger thisCnt = MIN(parallel, self.pendingLocation.count);
        return [[ReportTask alloc] initWithType:eReportTypeLocation andItems:[self.pendingLocation subarrayWithRange:NSMakeRange(0, thisCnt)]];
    }
    
    // check trip detail reporter task
    if (0 == self.pendingTripsDetail.count && !self.forceAsyncAll) {
        NSArray * newTrip = [[AnaDbManager deviceDb] tripsReadyToReport:NO];
        if (newTrip.count > 0) {
            self.pendingTripsDetail = [NSMutableArray arrayWithArray:newTrip];
            _tolTripAyncCnt = newTrip.count;
        }
    }
    if (self.pendingTripsDetail.count > 0) {
        NSInteger thisCnt = MIN(parallel, self.pendingTripsDetail.count);
        return [[ReportTask alloc] initWithType:eReportTypeTripDetail andItems:[self.pendingTripsDetail subarrayWithRange:NSMakeRange(0, thisCnt)]];
    }
    
    // check trip raw reporter task
    if (0 == self.pendingTripsRaw.count && !self.forceAsyncAll) {
        NSArray * newTripRaw = [[AnaDbManager deviceDb] tripRawsReadyToReport];
        if (newTripRaw.count > 0) {
            self.pendingTripsRaw = [NSMutableArray arrayWithArray:newTripRaw];
            _tolTripRawAyncCnt = newTripRaw.count;
        }
    }
    if (self.pendingTripsRaw.count > 0) {
        NSInteger thisCnt = MIN(parallel, self.pendingTripsRaw.count);
        return [[ReportTask alloc] initWithType:eReportTypeTripRaw andItems:[self.pendingTripsRaw subarrayWithRange:NSMakeRange(0, thisCnt)]];
    }
    
    return nil;
}

@end
