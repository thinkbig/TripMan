//
//  BackgroundDataProvider.h
//  Location
//
//  Created by taq on 11/1/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BaiduWeatherFacade.h"
#import "CTFavLocation.h"

#define kNotifyGoodLocationUpdated        @"kNotifyGoodLocationUpdated"

@interface BussinessDataProvider : NSObject

@property (nonatomic, strong) NSMutableArray *      fuckBaidu;

+ (instancetype)sharedInstance;

- (void) registerLoginLisener;
- (void) reCreateCoreDataDb;
- (void) asyncUserHistory;      // should call when user login, OR user manully async

- (void) updateCurrentCity:(successFacadeBlock)success forceUpdate:(BOOL)force;
- (void) updateAllRegionInfo:(BOOL)force;
- (void) updateRegionInfo:(ParkingRegion*)region force:(BOOL)force success:(successFacadeBlock)success failure:(failureFacadeBlock)failure;

- (void) updateRoadMarkForTrips:(TripSummary*)sum ofTurningPoints:(NSArray*)ptArr success:(successFacadeBlock)success failure:(failureFacadeBlock)failure;

+ (CLLocation*) lastGoodLocation;
- (NSDictionary*) lastGoodGpsItem;
- (void) updateLastGoodGpsItem:(GPSLogItem*)gps;

- (NSDateFormatter*) dateFormatterForFormatStr:(NSString*)format;

// some bussiness data storage
// CTFavLocation
- (NSArray*) favLocations;
- (void) putFavLocations:(NSArray*)favLoc;

// CTFavLocation    (统一起见，字段只用到city和name)
- (NSArray*) recentSearches;
- (void) putRecentSearches:(NSArray*)searches;

@end
