//
//  TicketDetailCell.h
//  TripMan
//
//  Created by taq on 11/26/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYPieChart.h"

#define ST_ADDRESS_TAG          10001
#define ED_ADDRESS_TAG          10002

@interface AddressEditCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UITextField *stAddress;
@property (weak, nonatomic) IBOutlet UITextField *edAddress;

@end

//////////////////////////////////////////////////////////////////////////////////

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

@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;

@property (weak, nonatomic) IBOutlet UILabel *labelVal11;
@property (weak, nonatomic) IBOutlet UILabel *label11;

@property (weak, nonatomic) IBOutlet UILabel *labelVal21;
@property (weak, nonatomic) IBOutlet UILabel *label21;
@property (weak, nonatomic) IBOutlet UILabel *labelVal22;
@property (weak, nonatomic) IBOutlet UILabel *label22;
@property (weak, nonatomic) IBOutlet UILabel *labelVal23;
@property (weak, nonatomic) IBOutlet UILabel *label23;

- (void) setLabel11Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;

- (void) setLabel21Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;
- (void) setLabel22Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;
- (void) setLabel23Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;

@end

//////////////////////////////////////////////////////////////////////////////////

@interface TicketDriveDetailCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;

@property (weak, nonatomic) IBOutlet UILabel *labelVal11;
@property (weak, nonatomic) IBOutlet UILabel *label11;
@property (weak, nonatomic) IBOutlet UILabel *labelVal12;
@property (weak, nonatomic) IBOutlet UILabel *label12;
@property (weak, nonatomic) IBOutlet UILabel *labelVal13;
@property (weak, nonatomic) IBOutlet UILabel *label13;

@property (weak, nonatomic) IBOutlet UILabel *labelVal21;
@property (weak, nonatomic) IBOutlet UILabel *label21;
@property (weak, nonatomic) IBOutlet UILabel *labelVal22;
@property (weak, nonatomic) IBOutlet UILabel *label22;
@property (weak, nonatomic) IBOutlet UILabel *labelVal23;
@property (weak, nonatomic) IBOutlet UILabel *label23;

- (void) setLabel11Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;
- (void) setLabel12Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;
- (void) setLabel13Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;

- (void) setLabel21Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;
- (void) setLabel22Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;
- (void) setLabel23Str:(NSString*)str withValue:(NSString*)val andUnit:(NSString*)unit;

@end

//////////////////////////////////////////////////////////////////////////////////

@interface TripDeleteCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@end

