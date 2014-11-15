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
#import "GPSTurningAnalyzer.h"
#import "DVSwitch.h"

@interface CarTripViewController ()

@property (nonatomic, strong) NSArray *             tripsToday;
@property (nonatomic, strong) NSDate *              currentDate;
@property (nonatomic, strong) NSDateFormatter *     dateFormatter;
@property (nonatomic, strong) DVSwitch *            switcher;

@end

@implementation CarTripViewController

- (void)internalInit
{
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat: @"MM.dd"];
    [self.dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tripCount.layer.cornerRadius = CGRectGetHeight(self.tripCount.bounds)/2.0f;
    
    self.carousel.type = iCarouselTypeTimeMachine;
    self.carousel.vertical = YES;
    self.carousel.bounceDistance = 0.4;
    self.carousel.decelerationRate = 0.7;
    self.carousel.itemOffset = CGPointMake(0, 15);
    
    // init segment view
    DVSwitch * switcher = [[DVSwitch alloc] initWithStringsArray:@[@"今天", @"本周", @"本月"]];
    self.switcher = switcher;
    self.switcher.frame = self.segmentView.bounds;
    self.switcher.sliderOffset = 2.0;
    self.switcher.cornerRadius = 14;
    [self.segmentView addSubview:self.switcher];
    [self.switcher setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.segmentView addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[switcher]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(switcher)]];
    [self.segmentView addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[switcher]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(switcher)]];
    [self.switcher setPressedHandler:^(NSUInteger index) {
        
        NSLog(@"Did press position on first switch at index: %lu", (unsigned long)index);
        
    }];

    self.currentDate = [NSDate date];
    
    UISwipeGestureRecognizer * swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showTomorrow)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer * swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showYestoday)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    
    self.slideShow.userInteractionEnabled = NO;
    [self.slideShow setAlpha:0];
    [self.slideShow setContentSize:CGSizeMake(320, self.slideShow.frame.size.height)];
    [self.slideShow setDidReachPageBlock:^(NSInteger reachedPage) {
        NSLog(@"Current Page: %li", reachedPage);
    }];
    
    // Add the animations
    //[self setupSlideShowSubviewsAndAnimations];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateTrips:self.currentDate];
    [UIView animateWithDuration:0.6 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.slideShow setAlpha:1];
    } completion:nil];
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

    NSArray * trips = [[TripsCoreDataManager sharedManager] tripStartFrom:[dateDay dateAtStartOfDay] toDate:[dateDay dateAtEndOfDay]];
    for (TripSummary * sum in trips) {
        GPSTurningAnalyzer * turnAnalyzer = [GPSTurningAnalyzer new];
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:sum withAnalyzer:@{@"TurningAnalyzer":turnAnalyzer}];
        if (0 == [sum.traffic_light_cnt integerValue]) {
            [[BussinessDataProvider sharedInstance] updateRoadMarkForTrips:sum ofTurningPoints:[turnAnalyzer.filter featurePoints] success:^(id cnt) {
                [self.carousel reloadData];
            } failure:nil];
        }
    }
    
    CGFloat totalDist = 0;
    CGFloat totalDuring = 0;
    CGFloat jamDist = 0;
    CGFloat jamDuring = 0;
    NSUInteger trafficLightCnt = 0;
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
        jamDist += [sum.traffic_jam_dist floatValue];
        jamDuring += [sum.traffic_jam_during floatValue];
        trafficLightCnt += [sum.traffic_light_cnt integerValue];
        maxSpeed = MAX(maxSpeed, [sum.max_speed floatValue]);
    }
    
    [self.carousel reloadData];
    [self.carousel scrollToItemAtIndex:0 animated:NO];
    if (self.tripsToday.count > 0) {
        [self.carousel scrollToItemAtIndex:self.tripsToday.count-1 duration:MIN(MAX(self.tripsToday.count/2.0, 0.5), 2.5)];
    }
    self.noResultView.hidden = (self.tripsToday.count > 0);
    
    [self.switcher setLabelText:[dateDay isToday] ? @"今天" : [self.dateFormatter stringFromDate:dateDay] forIndex:0];
    self.todayDist.text = [NSString stringWithFormat:@"%.1fkm", totalDist/1000.0];
    self.tripCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.tripsToday.count];
    self.todayDuring.text = [NSString stringWithFormat:@"%.fmin", totalDuring/60.0];
    self.todayMaxSpeed.text = [NSString stringWithFormat:@"%.1fkm/h", maxSpeed*3.6];
    self.jamDist.text = [NSString stringWithFormat:@"%.1fkm", jamDist/1000.0];
    self.jamDuring.text = [NSString stringWithFormat:@"%.fmin", jamDuring/60.0];
    self.trafficLightCnt.text = [NSString stringWithFormat:@"%lu处", (unsigned long)trafficLightCnt];
    self.trafficLightWaiting.text = @"未知";
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

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    TripTicketView * realView = [[view subviews] lastObject];
    if (nil == realView || ![realView isKindOfClass:[TripTicketView class]]) {
        realView = [[[NSBundle mainBundle] loadNibNamed:@"TripTicketView" owner:self options:nil] lastObject];
        realView.layer.cornerRadius = 10;
        
        view = [[UIView alloc] initWithFrame:realView.bounds];
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0, -4);
        view.layer.shadowOpacity = 0.6f;
        view.layer.shadowRadius = 4.0f;
        [view addSubview:realView];
    }
    [realView updateWithTripSummary:self.tripsToday[index]];
    
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
            return value;
        }
        case iCarouselOptionTilt:
        {
            return 0.16;
        }
        case iCarouselOptionSpacing:
        {
            return value * 0.3;
        }
        case iCarouselOptionFadeMinAlpha:
        {
            return value * 0.5;
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
