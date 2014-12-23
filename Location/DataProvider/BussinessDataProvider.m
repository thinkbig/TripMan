//
//  BackgroundDataProvider.m
//  Location
//
//  Created by taq on 11/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//  CLLocationCoordinate2DMake(31.3, 120.6);

#import "BussinessDataProvider.h"
#import "ParkingRegionDetail.h"
#import "WeatherInfo.h"
#import "BaiduReverseGeocodingWrapper.h"
#import "NSDate+Utilities.h"
#import "GeoTransformer.h"
#import "TSPair.h"
#import "TSCache.h"
#import "BaiduRoadMarkFacade.h"


#define kLastestCityAndDate         @"kLastestCityAndDate"

@interface BussinessDataProvider () {
    
    BOOL            _isWeatherUpdating;
    BOOL            _isRegionUpdating;
    
}

@property (nonatomic, strong) NSDictionary *                        latestCityDate;
@property (nonatomic, strong) NSMutableDictionary *                 dateFormaterDict;

@end

@implementation BussinessDataProvider

static BussinessDataProvider * _sharedProvider = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedProvider = [[BussinessDataProvider alloc] init];
    });
    return _sharedProvider;
}

- (id)init {
    self = [super init];
    if (self) {
        _latestCityDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastestCityAndDate];
        _fuckBaidu = [NSMutableArray array];
    }
    return self;
}

- (void) reCreateCoreDataDb
{
    [[GToolUtil sharedInstance] showPieHUDWithText:@"升级中..." andProgress:0];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        TripsCoreDataManager * manager = [TripsCoreDataManager sharedManager];
        
        NSArray * tripEvents = [[GPSLogger sharedLogger].dbLogger allTripsEvent];
        NSMutableArray * finishedTrips = [NSMutableArray arrayWithCapacity:tripEvents.count/2];
        TSPair * curPair = nil;
        for (GPSEventItem * item in tripEvents) {
            if (eGPSEventDriveStart == [item.eventType integerValue]) {
                if (curPair) {
                    curPair.second = item.timestamp;
                    [finishedTrips addObject:curPair];
                }
                curPair = TSPairMake(item.timestamp, nil, nil);
            } else if (eGPSEventDriveEnd == [item.eventType integerValue]) {
                if (curPair) {
                    curPair.second = item.timestamp;
                }
            }
            if (curPair.first && curPair.second) {
                [finishedTrips addObject:curPair];
                curPair = nil;
            }
        }
        
        for (TSPair * timePair in finishedTrips) {
            NSArray * tripExist = [manager tripStartFrom:timePair.first toDate:timePair.first];
            if (tripExist.count == 0) {
                [manager newTripAt:timePair.first endAt:timePair.second];
            }
        }
        [manager commit];
        
        [[GToolUtil sharedInstance] showPieHUDWithText:@"升级中..." andProgress:5];
        
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripStartFrom:nil toDate:nil shouldUpdateGlobalInfo:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyUpgradeComplete object:nil];
        [[GToolUtil sharedInstance] showPieHUDWithText:@"升级完成" andProgress:100];
    });
}

- (NSString *)currentCity
{
    return _latestCityDate[@"city"];
}

- (void) updateWeatherToday:(CLLocation*)loc
{
    if (_isWeatherUpdating) {
        return;
    }
    _isWeatherUpdating = YES;
    if (_latestCityDate && [((NSDate*)_latestCityDate[@"date"]) isToday]) {
        [self updateWeatherTodayForCity:_latestCityDate[@"city"]];
         return;
    }
    
    if (nil == loc) {
        loc = [BussinessDataProvider lastGoodLocation];
    }
    
    if (loc && CLLocationCoordinate2DIsValid(loc.coordinate))
    {
        BaiduReverseGeocodingWrapper * wrapper = [BaiduReverseGeocodingWrapper new];
        wrapper.coordinate = loc.coordinate;
        [wrapper requestWithSuccess:^(BMKReverseGeoCodeResult * result) {
            if (result.addressDetail.city.length > 0) {
                _latestCityDate = @{@"city": result.addressDetail.city, @"date": [NSDate date]};
                [[NSUserDefaults standardUserDefaults] setObject:_latestCityDate forKey:kLastestCityAndDate];
                [self updateWeatherTodayForCity:result.addressDetail.city];
            }
        } failure:^(NSError * err) {
            _isWeatherUpdating = NO;
        }];
    }
}

- (void) updateWeatherTodayForCity:(NSString*)city
{
    NSDate * dateDay = [[NSDate date] dateAtStartOfDay];
    NSArray * existInfos = [WeatherInfo where:@{@"city": city, @"date_day": dateDay} inContext:[TripsCoreDataManager sharedManager].tripAnalyzerContent];
    if (existInfos.count == 0 || ![((WeatherInfo*)existInfos[0]).is_analyzed doubleValue]) {
        BaiduWeatherFacade * facade = [BaiduWeatherFacade new];
        facade.city = city;
        [facade requestWithSuccess:^(BaiduWeatherModel * model) {
            WeatherInfo * info = [WeatherInfo create:@{@"city": city, @"date_day": [[NSDate date] dateAtStartOfDay]} inContext:[TripsCoreDataManager sharedManager].tripAnalyzerContent];
            info.city = city;
            info.date_day = dateDay;
            info.pm25 = model.pm25;
            if (model.weather_data.count > 0) {
                BaiduWeatherDetailModel * detailWeather = model.weather_data[0];
                info.weather = detailWeather.weather;
                info.wind = detailWeather.wind;
                info.temperature = detailWeather.temperature;
            }
            info.is_analyzed = @YES;
            [[TripsCoreDataManager sharedManager] commit];
            _isWeatherUpdating = NO;
        } failure:^(NSError * err) {
            _isWeatherUpdating = NO;
        }];
    }
}


- (void) updateAllRegionInfo:(BOOL)force
{
    NSArray * regions = [[TripsCoreDataManager sharedManager] allParkingDetails];
    if (regions.count == 0) {
        return;
    }

    for (ParkingRegionDetail * region in regions) {
        if (force || ![region.coreDataItem.is_analyzed boolValue]) {
            BaiduReverseGeocodingWrapper * wrapper = [BaiduReverseGeocodingWrapper new];
            wrapper.coordinate = [GeoTransformer earth2Baidu:region.region.center];
            [wrapper requestWithSuccess:^(BMKReverseGeoCodeResult* result) {
                ParkingRegion * coreRegion = region.coreDataItem;
                coreRegion.city = result.addressDetail.city;
                coreRegion.province = result.addressDetail.province;
                coreRegion.district = result.addressDetail.district;
                coreRegion.street = result.addressDetail.streetName;
                coreRegion.street_num = result.addressDetail.streetNumber;
                coreRegion.address = result.address;
                for (BMKPoiInfo * info in result.poiList) {
                    coreRegion.nearby_poi = info.name;
                    break;
                }
                coreRegion.is_analyzed = @YES;
                [[TripsCoreDataManager sharedManager] commit];
            } failure:^(NSError * err) {
                NSLog(@"update region info fail: %@", err);
            }];
        }
    }
}

- (void) updateRegionInfo:(ParkingRegion*)region force:(BOOL)force success:(successFacadeBlock)success failure:(failureFacadeBlock)failure
{
    if (force || ![region.is_analyzed boolValue]) {
        BaiduReverseGeocodingWrapper * wrapper = [BaiduReverseGeocodingWrapper new];
        wrapper.coordinate = [GeoTransformer earth2Baidu:CLLocationCoordinate2DMake([region.center_lat doubleValue], [region.center_lon doubleValue])];
        [wrapper requestWithSuccess:^(BMKReverseGeoCodeResult* result) {
            region.city = result.addressDetail.city;
            region.province = result.addressDetail.province;
            region.district = result.addressDetail.district;
            region.street = result.addressDetail.streetName;
            region.street_num = result.addressDetail.streetNumber;
            region.address = result.address;
            for (BMKPoiInfo * info in result.poiList) {
                region.nearby_poi = info.name;
                break;
            }
            region.is_analyzed = @YES;
            [[TripsCoreDataManager sharedManager] commit];
            if (success) {
                success(region);
            }
        } failure:failure];
    }
}


- (void) updateRoadMarkForTrips:(TripSummary*)sum ofTurningPoints:(NSArray*)ptArr success:(successFacadeBlock)success failure:(failureFacadeBlock)failure
{
    if (ptArr.count <= 1) {
        if (failure) {
            failure(ERR_MAKE(eInvalidInputError, @"无效的路段"));
        }
        return;
    }
    
    NSMutableArray * trafficLights = [NSMutableArray arrayWithCapacity:16];
    __block NSInteger trafficLightCnt = 0;
    __block NSError *error;
    dispatch_queue_t concurrent_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t downloadGroup = dispatch_group_create();
    
    for (int i = 0; i < ptArr.count-1; i++) {
        NSDictionary * first = ptArr[i];
        NSDictionary * second = ptArr[i+1];
        
        BaiduRoadMarkFacade * facade = [BaiduRoadMarkFacade new];
        facade.fromCoor = CLLocationCoordinate2DMake([first[@"lat"] doubleValue], [first[@"lon"] doubleValue]);
        facade.toCoor = CLLocationCoordinate2DMake([second[@"lat"] doubleValue], [second[@"lon"] doubleValue]);
        
        dispatch_group_enter(downloadGroup);
        [facade requestWithSuccess:^(BaiduMarkModel * model) {
            dispatch_barrier_async(concurrent_queue, ^{
                if (model.trafficLight) {
                    [trafficLights addObjectsFromArray:model.trafficLight];
                    trafficLightCnt += model.trafficLight.count-1;
                }
                dispatch_group_leave(downloadGroup);
            });
        } failure:^(NSError * err) {
            error = err;
            dispatch_group_leave(downloadGroup);
        }];
    }
    
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        if (trafficLightCnt > 0 || nil == error) {
            if (sum) {
                sum.traffic_light_tol_cnt = @(trafficLightCnt);
                
                NSMutableSet * lightSet = [NSMutableSet setWithArray:trafficLights];
                NSMutableArray * lightLocArr = [NSMutableArray arrayWithCapacity:lightSet.count];
                for (BaiduMarkItemModel * item in lightSet) {
                    [lightLocArr addObject:[item clLocation]];
                }
                
                CGFloat traffic_light_waiting = 0;
                NSUInteger jamInTrafficLight = 0;
                for (TrafficJam * jam in sum.traffic_jams) {
                    jam.near_traffic_light = @NO;
                    CLLocationCoordinate2D earthCoor = CLLocationCoordinate2DMake([jam.end_lat doubleValue], [jam.end_lon doubleValue]);
                    CLLocationCoordinate2D baiduCoor = [GeoTransformer earth2Baidu:earthCoor];
                    CLLocation * jamEndLoc = [[CLLocation alloc] initWithLatitude:baiduCoor.latitude longitude:baiduCoor.longitude];
                    for (CLLocation * lightLoc in lightLocArr) {
                        if ([jamEndLoc distanceFromLocation:lightLoc] < cTrafficLightRegionRadius) {
                            jam.near_traffic_light = @YES;
                            traffic_light_waiting += [jam.traffic_jam_during floatValue];
                            jamInTrafficLight++;
                            break;
                        }
                    }
                    jam.is_analyzed = @YES;
                }
                sum.traffic_light_jam_cnt = @(jamInTrafficLight);
                sum.traffic_light_waiting = @(traffic_light_waiting);
                [[GPSLogger sharedLogger].offTimeAnalyzer analyzeDaySum:sum.day_summary];
                [[GPSLogger sharedLogger].offTimeAnalyzer analyzeWeekSum:sum.day_summary.week_summary];
                
                [[TripsCoreDataManager sharedManager] commit];
            }
            if (success) {
                success(@(trafficLightCnt));
            }
        } else {
            if (failure) {
                failure(ERR_MAKE(eInvalidInputError, @"请求路标数据失败"));
            }
        }
    });
    
//    BaiduRoadMarkFacade * facade = [BaiduRoadMarkFacade new];
//    facade.fromCoor = [ptArr[0] locationCoordinate];
//    facade.toCoor = [[ptArr lastObject] locationCoordinate];
//    [facade requestWithSuccess:^(BaiduMarkModel * model) {
//        if (sum) {
//            sum.traffic_light_cnt = @(model.trafficLight.count);
//            [[TripsCoreDataManager sharedManager] commit];
//        }
//        if (success) {
//            success(@(model.trafficLight.count));
//        }
//    } failure:nil];
}

+ (CLLocation *)lastGoodLocation
{
    NSDictionary * lastGoodGPS = [[NSUserDefaults standardUserDefaults] objectForKey:kLastestGoodGPSData];
    if (lastGoodGPS) {
        return [[CLLocation alloc] initWithLatitude:[lastGoodGPS[@"lat"] doubleValue] longitude:[lastGoodGPS[@"lon"] doubleValue]];
    }
    return nil;
}

- (NSDateFormatter*) dateFormatterForFormatStr:(NSString*)format
{
    if (format.length == 0) {
        return nil;
    }
    if (nil == self.dateFormaterDict) {
        self.dateFormaterDict = [NSMutableDictionary dictionary];
    }
    NSDateFormatter * formater = self.dateFormaterDict[format];
    if (nil == formater) {
        formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:format];
        [formater setTimeZone:[NSTimeZone localTimeZone]];
        
        self.dateFormaterDict[format] = formater;
    }
    return formater;
}


- (NSDate*) latestUpdatedTripDate
{
    return [[TSCache sharedInst] keychainCacheForKey:@"latestUpdatedTripDate"];
}

- (NSDate*) latestUpdatedRawTripDate
{
    return [[TSCache sharedInst] keychainCacheForKey:@"latestUpdatedRawTripDate"];
}

@end
