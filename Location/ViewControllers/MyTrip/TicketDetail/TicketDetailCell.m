//
//  TicketDetailCell.m
//  TripMan
//
//  Created by taq on 11/26/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TicketDetailCell.h"
#import "NSAttributedString+Style.h"

@interface TicketDetailCell ()

@property (nonatomic, strong) NSArray *     colorArr;

@end

@implementation TicketDetailCell

- (void)awakeFromNib
{
    self.colorArr = @[[UIColor redColor], [UIColor orangeColor], [UIColor greenColor], [UIColor cyanColor]];
    
    self.chartCenter.layer.cornerRadius = CGRectGetHeight(self.chartCenter.bounds)/2.0;
    CGFloat height = CGRectGetHeight(self.pieChart.bounds);
    self.pieChart.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.pieChart.layer.cornerRadius = height/2.0;
    [self.pieChart setDataSource:self];
    [self.pieChart setStartPieAngle:M_PI_2];
    [self.pieChart setAnimationSpeed:1.0];
    [self.pieChart setShowPercentage:NO];
    [self.pieChart setShowLabel:NO];
    [self.pieChart setPieRadius:height/2.0-4.0];
    [self.pieChart setPieCenter:CGPointMake(height/2.0, height/2.0)];
    [self.pieChart setPieBackgroundColor:[UIColor clearColor]];
    [self.pieChart setUserInteractionEnabled:NO];
}

- (void) setTolDistStr:(NSString*)dist
{
    self.tolDist.attributedText = [NSAttributedString stringWithNumber:dist font:[UIFont boldSystemFontOfSize:50] color:UIColorFromRGB(0x82d13a) andUnit:@"km" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0x82d13a)];
}

- (void) setTolDuringStr:(NSString*)during
{
    self.tolDuring.attributedText = [NSAttributedString stringWithNumber:during font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"min" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setAvgSpeedStr:(NSString*)speed
{
    self.avgSpeed.attributedText = [NSAttributedString stringWithNumber:speed font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"km/h" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setMaxSpeedStr:(NSString*)speed
{
    self.maxSpeed.attributedText = [NSAttributedString stringWithNumber:speed font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"km/h" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0xbbbbbb)];
}

- (void)setChartArr:(NSArray *)chartArr
{
    _chartArr = chartArr;
    [self.pieChart reloadData];
}

#pragma mark - XYPieChartDataSource

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart
{
    return self.chartArr.count;
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
    return [self.chartArr[index] intValue];
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
    return self.colorArr[index % self.colorArr.count];
}

@end


//////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TicketJamDetailCell

- (void) setJamDistStr:(NSString*)dist
{
    self.jamDist.attributedText = [NSAttributedString stringWithNumber:dist font:[UIFont boldSystemFontOfSize:30] color:UIColorFromRGB(0x82d13a) andUnit:@"km" font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0x82d13a)];
}

- (void) setJamAvgSpeedStr:(NSString*)speed
{
    self.jamAvgSpeed.attributedText = [NSAttributedString stringWithNumber:speed font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:@"km/h" font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setJamDuringStr:(NSString*)during
{
    self.jamDuring.attributedText = [NSAttributedString stringWithNumber:during font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:@"min" font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setJamCountStr:(NSString*)count
{
    self.jamCount.attributedText = [NSAttributedString stringWithNumber:count font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:@"次" font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

@end

