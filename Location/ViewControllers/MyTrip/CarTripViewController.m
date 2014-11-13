//
//  CarTripViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarTripViewController.h"
#import "TripTicketView.h"
#import "MapDisplayViewController.h"
#import "NSDate+Utilities.h"

@interface CarTripViewController ()

@property (nonatomic, strong) NSArray *             tripsToday;
@property (nonatomic, strong) NSDate *              currentDate;
@property (nonatomic, strong) NSDateFormatter *     dateFormatter;

@end

@implementation CarTripViewController

- (void)internalInit
{
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat: @"yyyy-MM-dd"];
    [self.dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.currentDate = [NSDate date];
    
    UISwipeGestureRecognizer * swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showTomorrow)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.todayView addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer * swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showYestoday)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.todayView addGestureRecognizer:swipeRight];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateTrips:self.currentDate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showTomorrow
{
    if (self.currentDate && ![self.currentDate isToday] && [self.currentDate compare:[NSDate date]] == NSOrderedAscending) {
        self.currentDate = [self.currentDate dateByAddingDays:1];
        [self updateTrips:self.currentDate];
    }
}

- (void)showYestoday
{
    self.currentDate = [self.currentDate dateByAddingDays:-1];
    [self updateTrips:self.currentDate];
}

- (void)updateTrips:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = [NSDate date];
    }
    NSArray * trips = [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripStartFrom:[dateDay dateAtStartOfDay] toDate:[dateDay dateAtEndOfDay]];
    
    CGFloat totalDist = 0;
    CGFloat totalDuring = 0;
    CGFloat maxSpeed = 0;
    self.tripsToday = [[trips reverseObjectEnumerator] allObjects];
    for (TripSummary * sum in self.tripsToday) {
        [[BussinessDataProvider sharedInstance] updateRegionInfo:sum.region_group.start_region force:NO success:^(id) {
            [self.carousel reloadData];
        } failure:nil];
        [[BussinessDataProvider sharedInstance] updateRegionInfo:sum.region_group.end_region force:NO success:^(id) {
            [self.carousel reloadData];
        } failure:nil];
        totalDist += [sum.total_dist floatValue];
        totalDuring += [sum.total_during floatValue];
        maxSpeed = MAX(maxSpeed, [sum.max_speed floatValue]);
    }
    
    self.carousel.type = iCarouselTypeWheel;
    self.carousel.bounceDistance = 0.4;
    self.carousel.decelerationRate = 0.7;
    [self.carousel reloadData];
    
    [self.carousel scrollToItemAtIndex:0 animated:NO];
    if (self.tripsToday.count > 0) {
        [self.carousel scrollToItemAtIndex:self.tripsToday.count-1 duration:MIN(MAX(self.tripsToday.count/2.0, 0.5), 2.5)];
    }
    self.noResultView.hidden = (self.tripsToday.count > 0);
    
    self.todayLabel.text = [dateDay isToday] ? @"今日旅程" : [self.dateFormatter stringFromDate:dateDay];
    self.todayDist.text = [NSString stringWithFormat:@"%.2f km", totalDist/1000.0];
    self.todayDuring.text = [NSString stringWithFormat:@"%ld min", (long)(totalDuring/60.0)];
    self.todayMaxSpeed.text = [NSString stringWithFormat:@"%.2f km/h", maxSpeed*3.6];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark iCarouselDelegate

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return self.tripsToday.count;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(TripTicketView *)view
{
    if (nil == view) {
        view = [[[NSBundle mainBundle] loadNibNamed:@"TripTicketView" owner:self options:nil] lastObject];
        view.layer.cornerRadius = 10;
        view.layer.borderColor = [UIColor darkGrayColor].CGColor;
        view.layer.borderWidth = 2;
    }
    [view updateWithTripSummary:self.tripsToday[index]];
    
    return view;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            return NO;
        }
        case iCarouselOptionFadeMax:
        {
            return value;
        }
        case iCarouselOptionArc:
        {
            return M_PI * 0.4;
        }
        case iCarouselOptionRadius:
        {
            return value ;
        }
        case iCarouselOptionTilt:
        {
            return 0.8;
        }
        case iCarouselOptionSpacing:
        {
            return value * 1.02;
        }
        default:
        {
            return value;
        }
    }
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    MapDisplayViewController * mapVC = [[UIStoryboard storyboardWithName:@"Debug" bundle:nil] instantiateViewControllerWithIdentifier:@"MapDisplayView"];
    mapVC.tripSum = self.tripsToday[index];
    [self presentViewController:mapVC animated:YES completion:nil];
}

@end
