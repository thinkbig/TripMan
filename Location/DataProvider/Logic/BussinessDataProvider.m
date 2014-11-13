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

#define kLastestCityAndDate         @"kLastestCityAndDate"

@interface BussinessDataProvider () {
    
    BOOL            _isWeatherUpdating;
    BOOL            _isRegionUpdating;
    
}

@property (nonatomic, strong) NSDictionary *                        latestCityDate;

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
    TripsCoreDataManager * manager = [TripsCoreDataManager sharedManager];
    
    NSArray * tripEvents = [[GPSLogger sharedLogger].dbLogger allTripsEvent];
    NSMutableArray * finishedTrips = [NSMutableArray arrayWithCapacity:tripEvents.count/2];
    TSPair * curPair = nil;
    for (GPSEventItem * item in tripEvents) {
        if (eGPSEventDriveStart == [item.eventType integerValue]) {
            if (nil == curPair) {
                curPair = TSPairMake(item.timestamp, nil, nil);
            } else {
                curPair.second = item.timestamp;
            }
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
    
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripStartFrom:nil toDate:nil];
    [[BussinessDataProvider sharedInstance] updateAllRegionInfo:NO];
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
        NSDictionary * lastGoodGPS = [[NSUserDefaults standardUserDefaults] objectForKey:kLastestGoodGPSData];
        if (lastGoodGPS) {
            loc = [[CLLocation alloc] initWithLatitude:[lastGoodGPS[@"lat"] doubleValue] longitude:[lastGoodGPS[@"lon"] doubleValue]];
        }
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

@end
