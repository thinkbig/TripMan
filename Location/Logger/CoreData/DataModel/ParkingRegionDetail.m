//
//  ParkingRegionDetail.m
//  Location
//
//  Created by taq on 11/5/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "ParkingRegionDetail.h"
#import "NSString+ObjectiveSugar.h"
#import "NSString+ShiftEncode.h"

@interface ParkingRegionDetail ()

@property (nonatomic, strong) NSString *        pinyinMark;
@property (nonatomic, strong) NSString *        pinyinPoi;
@property (nonatomic, strong) NSString *        pinyinStreet;

@end

@implementation ParkingRegionDetail

- (void) copyInfoFromAnother:(ParkingRegionDetail*)detail
{
    self.region = detail.region;
    self.coreDataItem.parking_id = detail.coreDataItem.parking_id;
    self.coreDataItem.addi_data = detail.coreDataItem.addi_data;
    self.coreDataItem.addi_info = detail.coreDataItem.addi_info;
    self.coreDataItem.center_lat = detail.coreDataItem.center_lat;
    self.coreDataItem.center_lon = detail.coreDataItem.center_lon;
    self.coreDataItem.user_mark = detail.coreDataItem.user_mark;
    self.pinyinMark = detail.pinyinMark;
    
    if (detail.coreDataItem.address) {
        self.coreDataItem.address = detail.coreDataItem.address;
        self.coreDataItem.city = detail.coreDataItem.city;
        self.coreDataItem.district = detail.coreDataItem.district;
        self.coreDataItem.nearby_poi = detail.coreDataItem.nearby_poi;
        self.coreDataItem.province = detail.coreDataItem.province;
        self.coreDataItem.rate = detail.coreDataItem.rate;
        self.coreDataItem.street = detail.coreDataItem.street;
        self.coreDataItem.street_num = detail.coreDataItem.street_num;
        self.pinyinPoi = detail.pinyinPoi;
        self.pinyinStreet = detail.pinyinStreet;
    }
}

- (void) calculatePinyin
{
    ParkingRegion * region = self.coreDataItem;
    if (nil == self.pinyinMark) {
        self.pinyinMark = [[region.user_mark chinese2Pinyin] stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    if (nil == self.pinyinPoi) {
        self.pinyinPoi = [[region.nearby_poi chinese2Pinyin] stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    if (nil == self.pinyinStreet) {
        self.pinyinStreet = [[region.street chinese2Pinyin] stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
}

- (BOOL) matchString:(NSString*)str
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self calculatePinyin];
    });
    
    NSArray* words = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* pinyinStr = [words componentsJoinedByString:@""];
    if ([self.pinyinMark containsString:pinyinStr] ||
        [self.pinyinPoi containsString:pinyinStr] ||
        [self.pinyinStreet containsString:pinyinStr]) {
        return YES;
    }
    ParkingRegion * region = self.coreDataItem;
    NSArray * splitStr = [str split];
    for (NSString * oneStr in splitStr) {
        if ([region.user_mark containsString:oneStr] ||
            [region.nearby_poi containsString:oneStr] ||
            [region.street containsString:oneStr]) {
            return YES;
        }
    }
    return NO;
}

@end
