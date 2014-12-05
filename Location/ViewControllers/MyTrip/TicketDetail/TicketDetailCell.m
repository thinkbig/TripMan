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

- (void) setLabel11Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label11.text = str;
    self.labelVal11.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:30] color:UIColorFromRGB(0x82d13a) andUnit:unit font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0x82d13a)];
}

- (void) setLabel21Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label21.text = str;
    self.labelVal21.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:unit font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setLabel22Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label22.text = str;
    self.labelVal22.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:unit font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setLabel23Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label23.text = str;
    self.labelVal23.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:unit font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TicketDriveDetailCell

- (void) setLabel11Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label11.text = str;
    self.labelVal11.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:30] color:UIColorFromRGB(0x82d13a) andUnit:unit font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0x82d13a)];
}

- (void) setLabel12Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label12.text = str;
    self.labelVal12.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:unit font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setLabel13Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label13.text = str;
    self.labelVal13.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:unit font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setLabel21Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label21.text = str;
    self.labelVal21.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:30] color:UIColorFromRGB(0x82d13a) andUnit:unit font:[UIFont boldSystemFontOfSize:12] color:UIColorFromRGB(0x82d13a)];
}

- (void) setLabel22Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label22.text = str;
    self.labelVal22.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:unit font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

- (void) setLabel23Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label23.text = str;
    self.labelVal23.attributedText = [NSAttributedString stringWithNumber:val font:[UIFont boldSystemFontOfSize:18] color:[UIColor whiteColor] andUnit:unit font:[UIFont boldSystemFontOfSize:11] color:UIColorFromRGB(0xbbbbbb)];
}

@end