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

/*tatag
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) updateMonth
{
    if (![self.monthSum.is_analyzed boolValue]) {
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeMonthSum:self.monthSum];
    }
    CGFloat totalDist = [self.monthSum.total_dist floatValue];
    CGFloat totalDuring = [self.monthSum.total_during floatValue];
    NSUInteger tripCnt = [self.monthSum.trip_cnt integerValue];
    
    MonthSummary * userSum = [[AnaDbManager sharedInst] userMonthSumForDeviceMonthSum:self.monthSum];
    if (userSum) {
        totalDist += [userSum.total_dist floatValue];
        totalDuring += [userSum.total_during floatValue];
        tripCnt += [userSum.trip_cnt integerValue];
    }
    
    NSString * distStr = [NSString stringWithFormat:@"%.f", totalDist/1000.0];
    self.tolDistLabel.attributedText = [NSAttributedString stringWithNumber:distStr font:[self.tolDistLabel.font fontWithSize:50] color:self.tolDistLabel.textColor andUnit:@"km" font:[self.tolDistLabel.font fontWithSize:17] color:self.tolDistLabel.textColor];
    
    NSString * duringStr = [NSString stringWithFormat:@"%.f", totalDuring/60.0];
    self.tolDuringLabel.attributedText = [NSAttributedString stringWithNumber:duringStr font:[self.tolDuringLabel.font fontWithSize:30] color:self.tolDuringLabel.textColor andUnit:@"min" font:[self.tolDuringLabel.font fontWithSize:14] color:self.tolDuringLabel.textColor];
    
    self.tolCntLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)tripCnt];
}

@end
