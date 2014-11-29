//
//  TicketDetailCell.h
//  TripMan
//
//  Created by taq on 11/26/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYPieChart.h"

@interface TicketDetailCell : UICollectionViewCell <XYPieChartDataSource>

@property (weak, nonatomic) IBOutlet XYPieChart *   pieChart;
@property (weak, nonatomic) IBOutlet UIView *       chartCenter;

@property (weak, nonatomic) IBOutlet UILabel *tolDist;
@property (weak, nonatomic) IBOutlet UILabel *tolDuring;
@property (weak, nonatomic) IBOutlet UILabel *avgSpeed;
@property (weak, nonatomic) IBOutlet UILabel *maxSpeed;

@property (nonatomic, strong) NSArray *             chartArr;

- (void) setTolDistStr:(NSString*)dist;
- (void) setTolDuringStr:(NSString*)during;
- (void) setAvgSpeedStr:(NSString*)speed;
- (void) setMaxSpeedStr:(NSString*)speed;

@end

//////////////////////////////////////////////////////////////////////////////////

@interface TicketJamDetailCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *jamDist;
@property (weak, nonatomic) IBOutlet UILabel *jamAvgSpeed;
@property (weak, nonatomic) IBOutlet UILabel *jamDuring;
@property (weak, nonatomic) IBOutlet UILabel *jamCount;

- (void) setJamDistStr:(NSString*)dist;
- (void) setJamAvgSpeedStr:(NSString*)speed;
- (void) setJamDuringStr:(NSString*)during;
- (void) setJamCountStr:(NSString*)count;

@end
