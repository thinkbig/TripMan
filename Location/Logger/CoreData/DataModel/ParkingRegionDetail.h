//
//  ParkingRegionDetail.h
//  Location
//
//  Created by taq on 11/5/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParkingRegion.h"

@interface ParkingRegionDetail : NSObject

@property (nonatomic, strong) ParkingRegion *       coreDataItem;
@property (nonatomic, strong) CLCircularRegion *    region;
@property (nonatomic) NSUInteger                    parkingCnt;

- (void) copyInfoFromAnother:(ParkingRegionDetail*)detail;
- (BOOL) matchString:(NSString*)str;
- (void) calculatePinyin;

@end
