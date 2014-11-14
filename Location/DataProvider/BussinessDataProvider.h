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

@interface BussinessDataProvider : NSObject

@property (nonatomic, strong) NSString *            currentCity;
@property (nonatomic, strong) NSMutableArray *      fuckBaidu;

+ (instancetype)sharedInstance;

- (void) reCreateCoreDataDb;

- (void) updateWeatherToday:(CLLocation*)loc;
- (void) updateAllRegionInfo:(BOOL)force;
- (void) updateRegionInfo:(ParkingRegion*)region force:(BOOL)force success:(successFacadeBlock)success failure:(failureFacadeBlock)failure;

- (void) updateRoadMarkForTrips:(TripSummary*)sum ofTurningPoints:(NSArray*)ptArr success:(successFacadeBlock)success failure:(failureFacadeBlock)failure;

@end
