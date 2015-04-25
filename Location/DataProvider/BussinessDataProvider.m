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
#import "CTTrafficLightFacade.h"
#import "TripSummary+Fetcher.h"
#import "UserWrapper.h"
#import "AnaDbManager.h"
#import "ParkingRegion+Fetcher.h"
#import "CTBaseLocation.h"
#import "TripFilter.h"
#import "DeviceHistory.h"

#define kLastestCityAndDate          @"kLastestCityAndDate"
#define kUserFavLocation             @"kUserFavLocation"
#define kRecentSearchKey             @"kRecentSearchKey"

@interface BussinessDataProvider () {
    
    BOOL            _isRegionUpdating;
    
    NSDictionary *      _lastGoodGPS;
    
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

- (void) registerLoginLisener
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin) name:KEY_USER_LOGIN_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogout) name:KEY_USER_LOGOUT object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (CLLocation *) lastGoodLocation
{
    NSDictionary * dict = [[BussinessDataProvider sharedInstance] lastGoodGpsItem];
    if (nil == dict) {
        return nil;
    }
    return [[CLLocation alloc] initWithLatitude:[dict[@"lat"] doubleValue] longitude:[dict[@"lon"] doubleValue]];
}

- (NSDictionary*) lastGoodGpsItem
{
    if (nil == _lastGoodGPS) {
        _lastGoodGPS = [[NSUserDefaults standardUserDefaults] objectForKey:kLastestGoodGPSData];
    }
    return _lastGoodGPS;
}

- (void) updateLastGoodGpsItem:(GPSLogItem*)gps
{
    if (gps) {
        _lastGoodGPS = @{@"timestamp":gps.timestamp, @"lat":gps.latitude, @"lon":gps.longitude};
        [[NSUserDefaults standardUserDefaults] setObject:_lastGoodGPS forKey:kLastestGoodGPSData];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyGoodLocationUpdated object:nil];
    }
}

- (void) reCreateCoreDataDb
{
    [[GToolUtil sharedInstance] showPieHUDWithText:@"升级中..." andProgress:0];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        TripsCoreDataManager * manager = [AnaDbManager deviceDb];
        
        NSArray * tripEvents = [[GPSLogger sharedLogger].dbLogger allTripsEvent];
        NSMutableArray * finishedTrips = [NSMutableArray arrayWithCapacity:tripEvents.count/2];
        TSPair * curPair = nil;
        for (GPSEventItem * item in tripEvents) {
            eGPSEvent eventType = (eGPSEvent)[item.eventType integerValue];
            if (eGPSEventDriveStart == eventType) {
                if (curPair) {
                    curPair.second = item.timestamp;
                    [finishedTrips addObject:curPair];
                }
                curPair = TSPairMake(item.timestamp, nil, nil);
            } else if (eGPSEventDriveEnd == eventType) {
                if (curPair) {
                    curPair.second = item.timestamp;
                }
            } else if (eGPSEventDriveIgnore == eventType) {
                curPair = nil;
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyUpgradeComplete object:nil];
        });
        [[GToolUtil sharedInstance] showPieHUDWithText:@"升级完成" andProgress:100];
    });
}

- (void) asyncUserHistory
{
    
}

- (void) updateCurrentCity:(successFacadeBlock)success forceUpdate:(BOOL)force
{
    CLLocation * loc = [BussinessDataProvider lastGoodLocation];
    if (_latestCityDate.count > 0 && loc) {
        CLLocation * cityLoc = [[CLLocation alloc] initWithLatitude:[_latestCityDate[@"lat"] floatValue] longitude:[_latestCityDate[@"lon"] floatValue]];
        CGFloat dist = [cityLoc distanceFromLocation:loc];
        if ((force && dist < 2000) || (dist < 10000 && [((NSDate*)_latestCityDate[@"date"]) isToday])) {
            if (success) success(_latestCityDate[@"city"]);
            return;
        }
    }
    
    if (loc && CLLocationCoordinate2DIsValid(loc.coordinate))
    {
        BaiduReverseGeocodingWrapper * wrapper = [BaiduReverseGeocodingWrapper new];
        wrapper.coordinate = loc.coordinate;
        [wrapper requestWithSuccess:^(BMKReverseGeoCodeResult * result) {
            if (result.addressDetail.city.length > 0) {
                _latestCityDate = @{@"city": result.addressDetail.city, @"date": [NSDate date],
                                    @"lat": @(loc.coordinate.latitude), @"lon": @(loc.coordinate.longitude)};
                [[NSUserDefaults standardUserDefaults] setObject:_latestCityDate forKey:kLastestCityAndDate];
                if (success) success(_latestCityDate[@"city"]);
            } else {
                if (success) success(nil);
            }
        } failure:^(NSError * err) {
            if (success) success(nil);
        }];
    } else if (success) {
        success(nil);
    }
}

- (void) updateWeatherTodayForCity:(NSString*)city
{
    // 暂时不需要天气信息
    return;
    NSDate * dateDay = [[NSDate date] dateAtStartOfDay];
    NSArray * existInfos = [WeatherInfo where:@{@"city": city, @"date_day": dateDay} inContext:[AnaDbManager deviceDb].tripAnalyzerContent];
    if (existInfos.count == 0 || ![((WeatherInfo*)existInfos[0]).is_analyzed doubleValue]) {
        BaiduWeatherFacade * facade = [BaiduWeatherFacade new];
        facade.city = city;
        [facade requestWithSuccess:^(BaiduWeatherModel * model) {
            WeatherInfo * info = [WeatherInfo create:@{@"city": city, @"date_day": [[NSDate date] dateAtStartOfDay]} inContext:[AnaDbManager deviceDb].tripAnalyzerContent];
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
            [[AnaDbManager deviceDb] commit];
        } failure:^(NSError * err) {
        }];
    }
}


- (void) updateAllRegionInfo:(BOOL)force
{
    NSArray * regions = [[AnaDbManager deviceDb] allParkingDetails];
    if (regions.count == 0) {
        return;
    }

    for (ParkingRegionDetail * region in regions) {
        [self updateRegionInfo:region.coreDataItem force:force success:nil failure:nil];
    }
}

- (void) updateRegionInfo:(ParkingRegion*)region force:(BOOL)force success:(successFacadeBlock)success failure:(failureFacadeBlock)failure
{
    if ([region.is_temp boolValue]) {
        return;
    }
    if (force || ![region.is_analyzed boolValue])
    {
//        CLGeocoder *geocoder=[[CLGeocoder alloc] init];
//        [geocoder reverseGeocodeLocation:[region centerLocation]
//                       completionHandler:^(NSArray *placemarks,
//                                           NSError *error) 
//        {
//            if (error) {
//                if (failure) {
//                    failure(error);
//                }
//            } else {
//                CLPlacemark *placemark=[placemarks objectAtIndex:0];
//                region.city = placemark.locality;
//                region.province = placemark.administrativeArea;
//                region.district = placemark.subLocality;
//                region.street = placemark.thoroughfare;
//                region.street_num = placemark.subThoroughfare;
//                region.address = [NSString stringWithFormat:@"%@, %@, %@", placemark.locality, placemark.thoroughfare, placemark.name];
//                region.nearby_poi = placemark.name;
//                region.is_analyzed = @YES;
//                [[AnaDbManager deviceDb] commit];
//                if (success) {
//                    success(region);
//                }
//            }
//        }];
        
        BaiduReverseGeocodingWrapper * wrapper = [BaiduReverseGeocodingWrapper new];
        wrapper.coordinate = [GeoTransformer earth2Baidu:CLLocationCoordinate2DMake([region.center_lat doubleValue], [region.center_lon doubleValue])];
        [wrapper requestWithSuccess:^(BMKReverseGeoCodeResult* result) {
            region.city = result.addressDetail.city;
            region.province = result.addressDetail.province;
            region.district = result.addressDetail.district;
            region.street = result.addressDetail.streetName;
            region.street_num = result.addressDetail.streetNumber;
            region.address = result.address;
            CGFloat dist = MAXFLOAT;
            for (BMKPoiInfo * info in result.poiList) {
                CGFloat thisDist = [GToolUtil distFrom:wrapper.coordinate toCoor:info.pt];
                if (thisDist < dist) {
                    dist = thisDist;
                    region.nearby_poi = info.name;
                }
                break;
            }
            region.is_analyzed = @YES;
            [[AnaDbManager deviceDb] commit];
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
    
    //只把一个trip拆成2段，不拆过细是因为无法判断是否高架，而且因为gps点不能完全保证落在路上，拆分过细会导致误报非常多的红绿灯
    NSArray * locArr = nil;
    CLLocation * first = [GToolUtil dictToLocation:ptArr[0]];
    CLLocation * lastLoc = [GToolUtil dictToLocation:[ptArr lastObject]];
    if (ptArr.count > 2) {
        CLLocation * maxLoc = nil;     // 距离最远的点
        CGFloat maxDist = 0;
        for (int i = 1; i < ptArr.count; i++) {
            CLLocation * curLoc = [GToolUtil dictToLocation:ptArr[i]];
            CGFloat curDist = [first distanceFromLocation:curLoc];
            if (maxDist < curDist) {
                maxLoc = curLoc;
                maxDist = curDist;
            }
        }
        // 看最远的点是不是就在终点附近
        if ([maxLoc distanceFromLocation:lastLoc] < 500) {
            maxLoc = [GToolUtil dictToLocation:ptArr[ptArr.count/2]];
        }
        
        // 把ptArr筛选到只有3个点
        locArr = @[first, maxLoc, lastLoc];
    } else {
        locArr = @[first, lastLoc];
    }

    NSMutableArray * trafficLights = [NSMutableArray arrayWithCapacity:16];
    __block NSError *error;
    dispatch_queue_t concurrent_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t downloadGroup = dispatch_group_create();
    
    for (int i = 0; i < locArr.count-1; i++) {
        CLLocation * first = locArr[i];
        CLLocation * second = locArr[i+1];
        
        CTTrafficLightFacade * facade = [CTTrafficLightFacade new];
        facade.fromCoorBD = [GeoTransformer earth2Baidu:first.coordinate];
        facade.toCoorBD = [GeoTransformer earth2Baidu:second.coordinate];
        
        dispatch_group_enter(downloadGroup);
        [facade requestWithSuccess:^(NSArray * lights) {
            dispatch_barrier_async(concurrent_queue, ^{
                if (lights.count > 0) {
                    [trafficLights addObjectsFromArray:lights];
                }
                dispatch_group_leave(downloadGroup);
            });
        } failure:^(NSError * err) {
            error = err;
            dispatch_group_leave(downloadGroup);
        }];
    }
    
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        if (trafficLights.count > 0 || nil == error) {
            if (sum) {
                NSMutableSet * lightSet = [NSMutableSet setWithArray:trafficLights];
                NSMutableArray * lightLocArr = [NSMutableArray arrayWithCapacity:lightSet.count];
                for (CTBaseLocation * item in lightSet) {
                    [lightLocArr addObject:[item clLocation]];
                }
                
                sum.traffic_light_tol_cnt = @(lightLocArr.count);
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
                
                [[AnaDbManager deviceDb] commit];
            }
            if (success) {
                success(sum.traffic_light_tol_cnt);
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

- (NSArray*) bestGuessLocations:(NSInteger)limit formatToDetail:(BOOL)format
{
    if (limit <= 0) {
        limit = INT16_MAX;
    }
    
    NSMutableArray * finalArr = [NSMutableArray array];
    NSArray * rawRegions = [[AnaDbManager sharedInst] mostUsedParkingRegionLimit:0];
    
    // 顺序是：当前位置出发最近一次去过的地方 --》 当前位置当前时间范围出发按照去过次数排序 --》当前位置的出发地点 --> 当前位置非当前时间范围按照去过的次数排序 --》 非当前位置出发的地点按照去过的次数排序
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (curLoc)
    {
        NSArray * filterRegions = [TripFilter filterRegion:rawRegions byStartRegion:curLoc byDist:1500 onlyRecognized:YES];
        
        NSMutableArray * traveledGroups = [NSMutableArray array];
        NSMutableArray * traveledTrips = [NSMutableArray array];
        NSMutableArray * otherRegions = [NSMutableArray arrayWithArray:filterRegions];
        
        ParkingRegionDetail * stDetail = [[AnaDbManager sharedInst] parkingDetailForCoordinate:curLoc.coordinate minDist:500];
        if (stDetail) {
            NSArray * groups = [stDetail.coreDataItem.group_owner_st allObjects];
            for (RegionGroup * group in groups) {
                for (ParkingRegionDetail * detail in filterRegions) {
                    if (detail.coreDataItem == group.end_region) {
                        [traveledGroups addObject:group];
                        [otherRegions removeObject:detail];
                    }
                }
            }
            
            // 把 traveledGroups 每一个都选出一个最佳的trip
            for (RegionGroup * group in traveledGroups) {
                TripSummary * bestTrip = [self bestTripForRegionGroup:group];
                if (bestTrip) {
                    [traveledTrips addObject:bestTrip];
                }
            }
            
            // traveledTrips 再分2组，一组是出发时间和当前时间非常接近的trip，另一组是剩下的
            NSArray * sortedTrips = [traveledTrips sortedArrayUsingComparator:^NSComparisonResult(TripSummary * obj1, TripSummary * obj2) {
                return [obj2.start_date compare:obj1.start_date];
            }];
            NSMutableArray * sortedMutTrips = [NSMutableArray arrayWithArray:sortedTrips];
            NSArray * timeMatchTrips = [TripFilter filterTrips:sortedTrips byTime:[NSDate date] between:-60 toMinute:120];
            if (timeMatchTrips.count > 0) {
                [finalArr addObjectsFromArray:timeMatchTrips];
                for (TripSummary * removeSum in timeMatchTrips) {
                    [sortedMutTrips removeObject:removeSum];
                }
            }
            [finalArr addObjectsFromArray:sortedMutTrips];
            
            // 把当前位置的出发地点
            BOOL hasAdded = NO;
            TripSummary * lastTrip = [[AnaDbManager sharedInst] lastTrip];
            ParkingRegion * stRegion = lastTrip.region_group.start_region;
            for (TripSummary * sum in finalArr) {
                if (sum.region_group.end_region == stRegion) {
                    hasAdded = YES;
                    break;
                }
            }
            if (!hasAdded) {
                ParkingRegionDetail * findDetail = nil;
                for (ParkingRegionDetail * detail in otherRegions) {
                    if (detail.coreDataItem == stRegion) {
                        findDetail = detail;
                        break;
                    }
                }
                // 把出发地址点移到队列最前面
                if (findDetail) {
                    [otherRegions removeObject:findDetail];
                    [otherRegions insertObject:findDetail atIndex:0];
                }
            }
        }
        
        if (finalArr.count < limit) {
            // 把剩下的，没开过的location，按照停车次数排序
            NSArray * otherSortedRegion = [otherRegions sortedArrayUsingComparator:^NSComparisonResult(ParkingRegionDetail * obj1, ParkingRegionDetail * obj2) {
                if (obj1.coreDataItem.driveEndCount > obj2.coreDataItem.driveEndCount) {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                if (obj1.coreDataItem.driveEndCount < obj2.coreDataItem.driveEndCount) {
                    return (NSComparisonResult)NSOrderedDescending;
                }
                return (NSComparisonResult)NSOrderedSame;
            }];
            [finalArr addObjectsFromArray:otherSortedRegion];
        }
    }
    else
    {
        for (ParkingRegionDetail * detail in rawRegions) {
            [finalArr addObject:detail.coreDataItem];
        }
    }
    
    if (format) {
        NSMutableArray * formatArr = [NSMutableArray arrayWithCapacity:finalArr.count];
        NSArray * allDeviceDetail = [[AnaDbManager deviceDb] allParkingDetails];
        NSArray * allUserDetail = [[AnaDbManager userDb] allParkingDetails];
        for (id obj in finalArr) {
            ParkingRegion * curRegion = obj;
            if ([obj isKindOfClass:[TripSummary class]]) {
                curRegion = ((TripSummary*)obj).region_group.end_region;
            } else if ([obj isKindOfClass:[ParkingRegionDetail class]]) {
                [formatArr addObject:obj];
                continue;
            }
            BOOL find = NO;
            for (ParkingRegionDetail * detail in allDeviceDetail) {
                if (detail.coreDataItem == curRegion) {
                    [formatArr addObject:detail];
                    find = YES;
                    break;
                }
            }
            if (!find) {
                for (ParkingRegionDetail * detail in allUserDetail) {
                    if (detail.coreDataItem == curRegion) {
                        [formatArr addObject:detail];
                        find = YES;
                    }
                }
            }
        }
        return formatArr;
    }
    
    return finalArr;
}

- (TripSummary*) bestTripForRegionGroup:(RegionGroup*)group
{
    // 筛选条件：筛选是否当前时间范围内出发 --》 筛选是否节假日匹配 --》最近的一次旅程
    NSArray * allTrips = [group.trips allObjects];
    NSArray * finalTrips = allTrips;
    NSArray * filterTimeTrips = [TripFilter filterTrips:allTrips byTime:[NSDate date] between:-60 toMinute:120];
    if (filterTimeTrips.count > 0) {
        finalTrips = filterTimeTrips;
        NSArray * filterHolidayTrips = [TripFilter filterTrips:filterTimeTrips byDayType:eDayTypeAuto];
        if (filterHolidayTrips.count > 0) {
            finalTrips = filterHolidayTrips;
        }
    }
    
    NSArray * sortedArr = [finalTrips sortedArrayUsingComparator:^NSComparisonResult(TripSummary * obj1, TripSummary * obj2) {
        return [obj2.start_date compare:obj1.start_date];
    }];
    
    if (sortedArr.count > 0) {
        return sortedArr[0];
    }
    return nil;
}

- (void) userDidLogin
{
//    if ([[UserWrapper sharedInst] isLogin]) {
//        UserSecret * secret = [UserWrapper sharedInst].userSecret;
//        TripsCoreDataManager * manager = [TripsCoreDataManager sharedManager];
//        if (secret.userId && ![secret.userId isEqualToString:manager.uid]) {
//            [manager reset];
//            manager.uid = secret.userId;
//            manager.carNumber = secret.curCarNumber;
//        }
//    }
}

- (void) userDidLogout
{
//    [[TripsCoreDataManager sharedManager] reset];
}

- (CLLocationCoordinate2D) coorFromRegion:(ParkingRegion*)regrion {
    return CLLocationCoordinate2DMake([regrion.center_lat doubleValue], [regrion.center_lon doubleValue]);
}


#pragma mark - some bussiness data storage

- (NSString*) keyByUser:(NSString*)origKey
{
    NSString * uid = [GToolUtil sharedInstance].userId;
    if (uid) {
        return [uid stringByAppendingFormat:@"_%@", origKey];
    }
    return origKey;
}

- (NSArray*) favLocations
{
    NSArray * origLoc = [[TSCache sharedInst] fileCacheForKey:[self keyByUser:kUserFavLocation]];
    
    // merge with parking info
    for (CTFavLocation * favLoc in origLoc) {
        ParkingRegion * region = [[AnaDbManager sharedInst] parkingRegioinForId:favLoc.parking_id];
        if (region) {
            [favLoc updateWithParkingRegion:region];
        } else {
            ParkingRegionDetail * detail = [[AnaDbManager sharedInst] parkingDetailForCoordinate:favLoc.coordinate minDist:500];
            if (detail) {
                [favLoc updateWithParkingRegion:detail.coreDataItem];
            }
        }
    }
    
    return origLoc;
}

- (void) putFavLocations:(NSArray*)favLoc
{
    if (nil == favLoc) {
        favLoc = [NSArray array];
    }
    [[TSCache sharedInst] setFileCache:favLoc forKey:[self keyByUser:kUserFavLocation]];
}

- (NSArray*) recentSearches
{
    return [[TSCache sharedInst] fileCacheForKey:[self keyByUser:kRecentSearchKey]];
}

- (void) putRecentSearches:(NSArray*)searches
{
    if (nil == searches) {
        searches = [NSArray array];
    }
    [[TSCache sharedInst] setFileCache:searches forKey:[self keyByUser:kRecentSearchKey]];
}

- (void) updateDeviceHistory
{
    NSDate * now = [NSDate date];
    NSDictionary * plistDict = [[NSBundle mainBundle] infoDictionary];
    NSString * appVersion = [NSString stringWithFormat:@"appVersion=%@", plistDict[@"CFBundleVersion"]];
    NSString * deviceInfo = [NSString stringWithFormat:@"name=%@,model=%@", [UIDevice currentDevice].name, gDeviceType];
    NSString * uid = [GToolUtil sharedInstance].userId;
    if (nil == uid) uid = @"";
    NSString * udid = [GToolUtil sharedInstance].deviceId;
    if (nil == udid) udid = @"";
    
    DeviceHistory * device = nil;
    NSArray * history = [DeviceHistory where:nil inContext:[AnaDbManager deviceDb].tripAnalyzerContent order:@{@"created_at": @"DESC"} limit:@(1)];
    if (history.count > 0) {
        device = history[0];
        if (![uid isEqualToString:device.user_id] || ![udid isEqualToString:device.device_id] ||
            ![appVersion isEqualToString:device.app_info] || [deviceInfo isEqualToString:device.device_info]) {
            device = nil;
        } else {
            device.updated_at = now;
        }
    }
    if (nil == device) {
        device = [DeviceHistory createInContext:[AnaDbManager deviceDb].tripAnalyzerContent];
        device.user_id = uid;
        device.device_id = udid;
        device.app_info = appVersion;
        device.device_info = deviceInfo;
        device.created_at = now;
        device.updated_at = now;
    }
    [device save];
}

@end
