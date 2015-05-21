//
//  DriveSuggestCell.m
//  Location
//
//  Created by taq on 11/9/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "DriveSuggestCell.h"
#import "TripSummary.h"
#import "RegionGroup.h"
#import "ParkingRegion.h"
#import "NSAttributedString+Style.h"
#import "ParkingRegion+Fetcher.h"
#import "CTTrafficAbstractFacade.h"
#import "GeoTransformer.h"

@interface DriveSuggestCell ()

@property (nonatomic, strong) CTFavLocation *   favLoc;

@end

@implementation DriveSuggestCell

- (NSString*) safeText:(NSString*)str withDefault:(NSString*)defaultStr
{
    return str.length > 0 ? str : defaultStr;
}

- (void) updateWithFavLoc:(CTFavLocation*)favLoc;
{
    if (nil == self.favLoc) {
        [self updateTimeDuring:-1 andJamCnt:0];
    }
    self.favLoc = favLoc;
    
    self.toStreet.text = [self safeText:favLoc.street withDefault:@"未知地点"];
    self.toLabel.text = [self safeText:favLoc.name withDefault:@"未知地点"];
    
    CLLocation * mLoc = [BussinessDataProvider lastGoodLocation];
    CGFloat dist = [GToolUtil distFrom:mLoc.coordinate toCoor:favLoc.coordinate];
    
    if (dist > IGNORE_NAVIGATION_DIST) {
        // too far away
        self.suggestLabel.text = [NSString stringWithFormat:@"距当前位置约 %.f km", dist/1000.0];
        self.suggestLabel.font = [UIFont boldSystemFontOfSize:12];
        self.suggestLabel.textColor = COLOR_UNIT_GRAY;
        self.jamCntLabel.text = @"点击查看详情";
        self.jamCntLabel.font = [UIFont boldSystemFontOfSize:11];
        self.jamCntLabel.textColor = COLOR_UNIT_GRAY;
        self.jamDuringLabel.attributedText = [NSAttributedString stringWithNumber:@"- -" font:DigitalFontSize(24) color:[UIColor blackColor] andUnit:@"min" font:DigitalFontSize(14) color:[UIColor blackColor]];
    } else if (dist > 500) {
        ParkingRegionDetail * startDetail = [[AnaDbManager deviceDb] parkingDetailForCoordinate:mLoc.coordinate minDist:500];
        CTTrafficAbstractFacade * facade = [[CTTrafficAbstractFacade alloc] init];
        facade.fromCoorBaidu = [GeoTransformer earth2Baidu:mLoc.coordinate];
        facade.toCoorBaidu = [GeoTransformer earth2Baidu:favLoc.coordinate];
        if (startDetail) {
            facade.fromParkingId = startDetail.coreDataItem.parking_id;
            facade.toParkingId = favLoc.parking_id;
        }
        [facade requestWithSuccess:^(CTRoute * result) {
            if (favLoc == self.favLoc) {
                [result.most_jam calCoefWithStartLoc:mLoc andEndLoc:[favLoc clLocation]];

                BOOL hasJam = [result.most_jam trafficStat] > eStepTrafficOk;
                [self updateTimeDuring:[result.duration floatValue] andJamCnt:hasJam];
            }
        } failure:^(NSError * err) {
            [self updateTimeDuring:-1 andJamCnt:0];
        }];
    } else {
        [self updateTimeDuring:0 andJamCnt:0];
    }
    
    
}

- (void) updateTimeDuring:(NSTimeInterval)during andJamCnt:(NSInteger)jamCnt
{
    if (during >= 0 && during < 60) {
        during = 60;
    }
    NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
    
    if (during < 0) {
        self.suggestLabel.attributedText = [NSAttributedString stringWithNumber:@"--:--" font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"预计到达" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
        self.jamCntLabel.attributedText = [NSAttributedString stringWithNumber:@"-" font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"处拥堵" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
        
        self.jamDuringLabel.attributedText = [NSAttributedString stringWithNumber:@"- -" font:DigitalFontSize(24) color:[UIColor blackColor] andUnit:@"min" font:DigitalFontSize(14) color:[UIColor blackColor]];
    } else {
        self.suggestLabel.attributedText = [NSAttributedString stringWithNumber:[formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:during]] font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"预计到达" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
        self.jamCntLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%ld", jamCnt] font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"处拥堵" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
        
        self.jamDuringLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%d", (int)(during/60)] font:DigitalFontSize(24) color:[UIColor blackColor] andUnit:@"min" font:DigitalFontSize(14) color:[UIColor blackColor]];
    }
}

@end

/////////////////////////////////////////////////////////////////////////////////

typedef NS_ENUM(NSUInteger, ePOICellSourceType) {
    ePOICellSourceTypeParking,
    ePOICellSourceTypeBaidu
};

@interface DriveSuggestPOICell ()

@property (nonatomic, strong) ParkingRegionDetail * location;
@property (nonatomic, strong) BMKPoiInfo *          bdInfo;
@property (nonatomic) ePOICellSourceType            soureType;

@end

@implementation DriveSuggestPOICell

- (void) useMockData
{
    self.destPOILabel.text = @"西湖文化广场";
    self.destStreetLabel.text = @"中山北路20号";
    
    NSTimeInterval during = 400.0;
    self.estimateDuringLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%d", (int)(during/60)] font:DigitalFontSize(24) color:[UIColor whiteColor] andUnit:@"min" font:DigitalFontSize(14) color:COLOR_UNIT_GRAY];
    self.duringStatusLabel.textColor = COLOR_STAT_GREEN;
}

- (void) updateWithLocation:(ParkingRegionDetail*)loc
{
    self.soureType = ePOICellSourceTypeParking;
    if (self.location != loc) {
        self.location = loc;
        self.destPOILabel.text = [loc.coreDataItem nameWithDefault:@"未知位置"];
        self.destStreetLabel.text = loc.coreDataItem.street.length > 0 ? loc.coreDataItem.street : @"未知街道";
        
        [self updateTimeDuring:@"- -"];
        self.duringStatusLabel.textColor = COLOR_STAT_GREEN;
        self.iconStatusImage.image = [UIImage imageNamed:@"greenicon"];
    }
    
    
    CLLocation * mLoc = [BussinessDataProvider lastGoodLocation];
    CGFloat dist = [mLoc distanceFromLocation:[loc.coreDataItem centerLocation]];
    
    if (dist > IGNORE_NAVIGATION_DIST) {
        // too far away
        [self updateTimeDuring:@"- -"];
        self.duringStatusLabel.text = @"点击查看详情";
    } else if (dist > 500) {
        ParkingRegionDetail * startDetail = [[AnaDbManager deviceDb] parkingDetailForCoordinate:mLoc.coordinate minDist:500];
        CTTrafficAbstractFacade * facade = [[CTTrafficAbstractFacade alloc] init];
        facade.fromCoorBaidu = [GeoTransformer earth2Baidu:mLoc.coordinate];
        facade.toCoorBaidu = [GeoTransformer earth2Baidu:loc.region.center];
        if (startDetail) {
            facade.fromParkingId = startDetail.coreDataItem.parking_id;
            facade.toParkingId = loc.coreDataItem.parking_id;
        }
        [facade requestWithSuccess:^(CTRoute * result) {
            if (loc == self.location) {
                NSNumber * during = result.duration;
                [self updateTimeDuring:[NSString stringWithFormat:@"%d", (int)([during floatValue]/60)]];
                
                eStepTraffic stat = [result trafficStat];
                if (eStepTrafficVerySlow == stat) {
                    self.iconStatusImage.image = [UIImage imageNamed:@"yellowicon"];
                } else if (eStepTrafficSlow == stat) {
                    self.iconStatusImage.image = [UIImage imageNamed:@"yellowicon"];
                } else {
                    self.iconStatusImage.image = [UIImage imageNamed:@"greenicon"];
                }
            }
        } failure:^(NSError * err) {
            //NSLog(@"asdfasdf = %@", err);
        }];
    } else {
        [self updateTimeDuring:@"1"];
    }
}

- (void) updateWithBDPoiInfo:(BMKPoiInfo*)poiInfo
{
    self.soureType = ePOICellSourceTypeBaidu;
    if (self.bdInfo != poiInfo) {
        self.bdInfo = poiInfo;
        self.destPOILabel.text = poiInfo.name;
        self.destStreetLabel.text = poiInfo.address;
        
        [self updateTimeDuring:@"- -"];
        self.duringStatusLabel.textColor = COLOR_STAT_GREEN;
        self.iconStatusImage.image = [UIImage imageNamed:@"greenicon"];
    }
    
    
    CLLocation * mLoc = [BussinessDataProvider lastGoodLocation];
    CLLocation * infoLoc = [[CLLocation alloc] initWithLatitude:poiInfo.pt.latitude longitude:poiInfo.pt.longitude];
    CGFloat dist = [mLoc distanceFromLocation:infoLoc];
    
    if (dist > IGNORE_NAVIGATION_DIST) {
        // too far away
        [self updateTimeDuring:@"- -"];
        self.duringStatusLabel.text = @"点击查看详情";
    } else if (dist > 500) {
        CTTrafficAbstractFacade * facade = [[CTTrafficAbstractFacade alloc] init];
        facade.fromCoorBaidu = [GeoTransformer earth2Baidu:mLoc.coordinate];
        facade.toCoorBaidu = poiInfo.pt;
        [facade requestWithSuccess:^(CTRoute * result) {
            if (poiInfo == self.bdInfo) {
                NSNumber * during = result.duration;
                [self updateTimeDuring:[NSString stringWithFormat:@"%d", (int)([during floatValue]/60)]];
                
                eStepTraffic stat = [result trafficStat];
                if (eStepTrafficVerySlow == stat) {
                    self.iconStatusImage.image = [UIImage imageNamed:@"yellowicon"];
                } else if (eStepTrafficSlow == stat) {
                    self.iconStatusImage.image = [UIImage imageNamed:@"yellowicon"];
                } else {
                    self.iconStatusImage.image = [UIImage imageNamed:@"greenicon"];
                }
            }
        } failure:^(NSError * err) {
            //NSLog(@"asdfasdf = %@", err);
        }];
    } else {
        [self updateTimeDuring:@"1"];
    }
}

- (void) updateTimeDuring:(NSString*)timeStr
{
    self.estimateDuringLabel.attributedText = [NSAttributedString stringWithNumber:timeStr font:DigitalFontSize(24) color:[UIColor whiteColor] andUnit:@"min" font:DigitalFontSize(14) color:COLOR_UNIT_GRAY];
    self.duringStatusLabel.text = @"预计耗时";
}

@end

/////////////////////////////////////////////////////////////////////////////////

@implementation SuggestPOICategoryCell

@end

/////////////////////////////////////////////////////////////////////////////////

@implementation SearchPOIHeader

- (void)awakeFromNib
{
    self.backgroundMask.layer.shadowColor = [UIColor blackColor].CGColor;
    self.backgroundMask.layer.shadowOffset = CGSizeMake(0, 5);
    self.backgroundMask.layer.shadowOpacity = 0.5f;
    self.backgroundMask.layer.shadowRadius = 3.0f;
}

@end
