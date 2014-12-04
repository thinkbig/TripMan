//
//  TripMonthView.m
//  TripMan
//
//  Created by taq on 12/3/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripMonthView.h"
#import "NSAttributedString+Style.h"

@implementation TripMonthView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    self.tolCntLabel.layer.cornerRadius = CGRectGetHeight(self.tolCntLabel.bounds)/2.0f;
}

- (void) updateMonth
{
    if (![self.monthSum.is_analyzed boolValue]) {
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeMonthSum:self.monthSum];
    }
    CGFloat totalDist = [self.monthSum.total_dist floatValue];
    CGFloat totalDuring = [self.monthSum.total_during floatValue];
    NSUInteger tripCnt = [self.monthSum.trip_cnt integerValue];
    
    NSString * distStr = [NSString stringWithFormat:@"%.f", totalDist/1000.0];
    self.tolDistLabel.attributedText = [NSAttributedString stringWithNumber:distStr font:[UIFont boldSystemFontOfSize:50] color:UIColorFromRGB(0x82d13a) andUnit:@"km" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0x82d13a)];
    
    NSString * duringStr = [NSString stringWithFormat:@"%.f", totalDuring/60.0];
    self.tolDuringLabel.attributedText = [NSAttributedString stringWithNumber:duringStr font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"min" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0xbbbbbb)];
    
    self.tolCntLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)tripCnt];
}

@end
