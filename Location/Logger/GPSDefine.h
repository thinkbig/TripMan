//
//  GPSDefine.h
//  Location
//
//  Created by taq on 9/15/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#ifndef Location_GPSDefine_h
#define Location_GPSDefine_h

#import "GPSLogger.h"
#import "AnaDbManager.h"

//#define NSLog(frmt, ...)   DDLogDebug(frmt, ##__VA_ARGS__)

#define LogContextGPS       10001
#define LOG_FLAG_GPS_DATA   (1 << 6)
#define LOG_FLAG_GPS_EVENT  (1 << 7)
#define LogLevelGPS         LOG_LEVEL_ALL

#define LOG_MAYBE2(async, lvl, flg, ctx, fnct, tstamp, frmt, ...) \
        do { if(lvl & flg) LOG_MACRO2(async, lvl, flg, ctx, nil, fnct, tstamp, frmt, ##__VA_ARGS__); } while(0)

#define LOG_MACRO2(isAsynchronous, lvl, flg, ctx, atag, fnct, tstamp, frmt, ...) \
        [DDLog log:isAsynchronous                                       \
            level:(int)lvl                                             \
            flag:flg                                                  \
            context:ctx                                                  \
            file:__FILE__                                             \
            function:fnct                                                 \
            line:__LINE__                                             \
            tag:atag                                                 \
      timestamp:tstamp                                              \
            format:(frmt), ##__VA_ARGS__]

//#define GPSLogInternal(frmt, ...)   SYNC_LOG_OBJC_MAYBE(LogLevelGPS, LOG_FLAG_GPS_DATA, LogContextGPS, frmt, ##__VA_ARGS__)
#define GPSLogInternal(tstamp, frmt, ...)   LOG_MAYBE2(YES, LogLevelGPS, LOG_FLAG_GPS_DATA, LogContextGPS, __PRETTY_FUNCTION__, tstamp, frmt, ##__VA_ARGS__)
#define GPSEventInternal(tstamp, frmt, ...)   LOG_MAYBE2(YES, LogLevelGPS, LOG_FLAG_GPS_EVENT, LogContextGPS, __PRETTY_FUNCTION__, tstamp, frmt, ##__VA_ARGS__)


// common const define

#define cAvgNoiceSpeed                         (500.0/3.6)     //  > 3000 km/h
#define cAvgDrivingSpeed                       (20.0/3.6)       //  > 15 km/h
#define cAvgTrafficJamSpeed                    (10.0/3.6)        //  < 5 km/h
#define cAvgRunningSpeed                       (8.0/3.6)        //  > 10 km/h
#define cAvgWalkingSpeed                       (5.0/3.6)        //  < 5 km/h
#define cAvgStationarySpeed                    (2.0/3.6)        //  < 2 km/h

#define cDirveStartSamplePoint                 4
#define cDirveEndSamplePoint                   12
#define cOntOfDateThreshold                    (60*30)          // if the last gps data is over 30*60s ealier, force end unfinished trip
#define cCanStopMonitoringThreshold            (60*3)

#define cInsDrivingSpeed                       (30.0/3.6)       //  > 15 km/h
#define cInsTrafficJamSpeed                    (20.0/3.6)        //  < 5 km/h
#define cInsRunningSpeed                       (10.0/3.6)       //  > 10 km/h
#define cInsWalkingSpeed                       (5.0/3.6)        //  < 5 km/h
#define cInsStationarySpeed                    (2/3.6)          //  < 2 km/h

#define cDriveStartThreshold                    10
#define cMoveStartRecordThreshold               (60*3)          // must bigger than cDriveStartThreshold
#define cDriveEndThreshold                      (60*8)
#define cHeavyTrafficJamThreshold               (60*3)

#define cStartLocErrorDist                      2000
#define cReagionRadius                          120
#define cParkingRegionRadius                    300
#define cTrafficLightRegionRadius               150

// public define

#define kNotifyExitReagion              @"kNotifyExitReagion"
#define kNotifyTripStatChange           @"kNotifyTripStatChange"
#define kNotifyTripDidEnd               @"kNotifyTripDidEnd"    // did end one trip (get the end date)
#define kNotifyGpsLost                  @"kNotifyGpsLost"

#define kLastestGoodGPSData             @"kLastestGoodGPSData"  //@{@"lat":lat, @"lon":lon, @"timestamp":timestamp}

#define NotNulStr(str_)                 ((str_)?(str_):@"")

#define GPSLog(loc_, acc_)              GPSLogInternal((loc_).timestamp, @"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f", (loc_).coordinate.latitude, (loc_).coordinate.longitude, (loc_).altitude, (loc_).horizontalAccuracy, (loc_).verticalAccuracy, (loc_).course, (loc_).speed, (acc_).acceleration.x, (acc_).acceleration.y, (acc_).acceleration.z)
#define GPSLog2(loc_, acc_, speed_)              GPSLogInternal((loc_).timestamp, @"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f", (loc_).coordinate.latitude, (loc_).coordinate.longitude, (loc_).altitude, (loc_).horizontalAccuracy, (loc_).verticalAccuracy, (loc_).course, (speed_), (acc_).acceleration.x, (acc_).acceleration.y, (acc_).acceleration.z)


#define GPSEvent(tstamp_, type_)                            GPSEvent3((tstamp_), (type_), nil)
#define GPSEvent3(tstamp_, type_, msg_)                     GPSEvent5((tstamp_), (type_), nil, nil, (msg_))
#define GPSEvent5(tstamp_, type_, region_, group_, msg_)    GPSEventInternal((tstamp_), @"%ld,%f,%f,%f,%@,%@,%@", (long)(type_), ((CLCircularRegion*)(region_)).center.latitude, ((CLCircularRegion*)(region_)).center.longitude, ((CLCircularRegion*)(region_)).radius, NotNulStr(((CLCircularRegion*)(region_)).identifier), NotNulStr(group_), NotNulStr(msg_))


// debug config
#define DEBUG_MODE      NO

#endif
