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
    
    if (dist > 500) {
        CTTrafficAbstractFacade * facade = [[CTTrafficAbstractFacade alloc] init];
        facade.fromCoorBaidu = [GeoTransformer earth2Baidu:mLoc.coordinate];
        facade.toCoorBaidu = [GeoTransformer earth2Baidu:favLoc.coordinate];
        [facade requestWithSuccess:^(id result) {
            if (favLoc == self.favLoc) {
                NSNumber * during = result[@"duration"];
                NSNumber * jamCnt = result[@"status"];
                [self updateTimeDuring:[during floatValue] andJamCnt:[jamCnt floatValue]];
            }
        } failure:^(NSError * err) {
            [self updateTimeDuring:-1 andJamCnt:0];
            //NSLog(@"asdfasdf = %@", err);
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
        self.suggestLabel.attributedText = [NSAttributedString stringWithNumber:@"--:--" font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"建议出行" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
        self.jamCntLabel.attributedText = [NSAttributedString stringWithNumber:@"-" font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"处拥堵" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
        
        self.jamDuringLabel.attributedText = [NSAttributedString stringWithNumber:@"-" font:DigitalFontSize(24) color:[UIColor blackColor] andUnit:@"min" font:DigitalFontSize(14) color:[UIColor blackColor]];
    } else {
        self.suggestLabel.attributedText = [NSAttributedString stringWithNumber:[formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:during]] font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"建议出行" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
        self.jamCntLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%ld", jamCnt] font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:@"处拥堵" font:[UIFont boldSystemFontOfSize:11] color:COLOR_UNIT_GRAY];
        
        self.jamDuringLabel.attributedText = [NSAttributedString stringWithNumber:[NSString stringWithFormat:@"%d", (int)(during/60)] font:DigitalFontSize(24) color:[UIColor blackColor] andUnit:@"min" font:DigitalFontSize(14) color:[UIColor blackColor]];
    }
}

@end

/////////////////////////////////////////////////////////////////////////////////

@interface DriveSuggestPOICell ()

@property (nonatomic, strong) ParkingRegionDetail * location;

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
    if (self.location != loc) {
        self.location = loc;
        self.destPOILabel.text = [loc.coreDataItem nameWithDefault:@"未知位置"];
        self.destStreetLabel.text = loc.coreDataItem.street.length > 0 ? loc.coreDataItem.street : @"未知街道";
        
        [self updateTimeDuring:@"- -"];
        self.duringStatusLabel.textColor = COLOR_STAT_GREEN;
    }
    
    
    CLLocation * mLoc = [BussinessDataProvider lastGoodLocation];
    CGFloat dist = [GToolUtil distFrom:mLoc.coordinate toCoor:loc.region.center];
    
    if (dist > 500) {
        CTTrafficAbstractFacade * facade = [[CTTrafficAbstractFacade alloc] init];
        facade.fromCoorBaidu = [GeoTransformer earth2Baidu:mLoc.coordinate];
        facade.toCoorBaidu = [GeoTransformer earth2Baidu:loc.region.center];
        [facade requestWithSuccess:^(id result) {
            if (loc == self.location) {
                NSNumber * during = result[@"duration"];
                [self updateTimeDuring:[NSString stringWithFormat:@"%d", (int)([during floatValue]/60)]];
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
