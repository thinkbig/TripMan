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
    self.pieChart.backgroundColor = [UIColor clearColor];
    //self.pieChart.layer.cornerRadius = height/2.0;
    [self.pieChart setDataSource:self];
    [self.pieChart setStartPieAngle:M_PI_2];
    [self.pieChart setAnimationSpeed:1.0];
    [self.pieChart setShowPercentage:NO];
    [self.pieChart setShowLabel:NO];
    [self.pieChart setPieRadius:height/2.0-7.0];
    [self.pieChart setPieCenter:CGPointMake(height/2.0, height/2.0-1)];
    [self.pieChart setPieBackgroundColor:[UIColor clearColor]];
    [self.pieChart setUserInteractionEnabled:NO];
}

- (void) setTolDistStr:(NSString*)dist
{
    self.tolDist.attributedText = [NSAttributedString stringWithNumber:dist font:DigitalFontSize(50) color:COLOR_STATUS_BLUE andUnit:@"km" font:DigitalFontSize(12) color:COLOR_STATUS_BLUE];
}

- (void) setTolDuringStr:(NSString*)during
{
    self.tolDuring.attributedText = [NSAttributedString stringWithNumber:during font:DigitalFontSize(24) color:[UIColor whiteColor] andUnit:@"min" font:DigitalFontSize(12) color:COLOR_UNIT_GRAY];
}

- (void) setAvgSpeedStr:(NSString*)speed
{
    self.avgSpeed.attributedText = [NSAttributedString stringWithNumber:speed font:DigitalFontSize(24) color:[UIColor whiteColor] andUnit:@"km/h" font:DigitalFontSize(12) color:COLOR_UNIT_GRAY];
}

- (void) setMaxSpeedStr:(NSString*)speed
{
    self.maxSpeed.attributedText = [NSAttributedString stringWithNumber:speed font:DigitalFontSize(24) color:[UIColor whiteColor] andUnit:@"km/h" font:DigitalFontSize(12) color:COLOR_UNIT_GRAY];
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
    self.labelVal11.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(30) color:COLOR_STATUS_BLUE andUnit:unit font:DigitalFontSize(12) color:COLOR_STATUS_BLUE];
}

- (void) setLabel21Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label21.text = str;
    self.labelVal21.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:unit font:DigitalFontSize(11) color:COLOR_UNIT_GRAY];
}

- (void) setLabel22Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label22.text = str;
    self.labelVal22.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:unit font:DigitalFontSize(11) color:COLOR_UNIT_GRAY];
}

- (void) setLabel23Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label23.text = str;
    self.labelVal23.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:unit font:DigitalFontSize(11) color:COLOR_UNIT_GRAY];
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TicketDriveDetailCell

- (void) setLabel11Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label11.text = str;
    self.labelVal11.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(30) color:COLOR_STATUS_BLUE andUnit:unit font:DigitalFontSize(12) color:COLOR_STATUS_BLUE];
}

- (void) setLabel12Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label12.text = str;
    self.labelVal12.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:unit font:DigitalFontSize(11) color:COLOR_UNIT_GRAY];
}

- (void) setLabel13Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label13.text = str;
    self.labelVal13.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:unit font:DigitalFontSize(11) color:COLOR_UNIT_GRAY];
}

- (void) setLabel21Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label21.text = str;
    self.labelVal21.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(30) color:COLOR_STATUS_BLUE andUnit:unit font:DigitalFontSize(12) color:COLOR_STATUS_BLUE];
}

- (void) setLabel22Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label22.text = str;
    self.labelVal22.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:unit font:DigitalFontSize(11) color:COLOR_UNIT_GRAY];
}

- (void) setLabel23Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit
{
    self.label23.text = str;
    self.labelVal23.attributedText = [NSAttributedString stringWithNumber:val font:DigitalFontSize(17) color:[UIColor whiteColor] andUnit:unit font:DigitalFontSize(11) color:COLOR_UNIT_GRAY];
}

@end