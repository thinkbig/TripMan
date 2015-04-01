//
//  GPSInstJamAnalyzer.h
//  TripMan
//
//  Created by taq on 3/31/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, eJamAnalyzeStat) {
    eJamAnalyzeStatNone = 0,
    eJamAnalyzeStatPendding,
    eJamAnalyzeStatMaybe,
    eJamAnalyzeStatConfirmed
};

@interface GPSInstJamAnalyzer : NSObject

@property (nonatomic) eJamAnalyzeStat       anaStat;

- (void) appendGPSInfo:(GPSLogItem*)gps;
- (void) reset;

@end
