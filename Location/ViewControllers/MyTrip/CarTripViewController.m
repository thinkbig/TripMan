//
//  CarTripViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarTripViewController.h"
#import "TripTicketView.h"
#import "TripTodayView.h"
#import "MapDisplayViewController.h"
#import "NSDate+Utilities.h"
#import "GPSTurningAnalyzer.h"
#import "DVSwitch.h"

@interface CarTripViewController ()

@property (nonatomic, strong) NSArray *             tripsYestoday;
@property (nonatomic, strong) NSArray *             tripsToday;
@property (nonatomic, strong) NSArray *             tripsTomorrow;

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
    self.tripsToday = [self fetchTripsForDate:self.currentDate];
    self.tripsYestoday = [self fetchTripsForDate:[self.currentDate dateBySubtractingDays:1]];
    
    [self reloadContent];
    
    __block CarTripViewController * nonRetainSelf = self;
    [self.slideShow setAlpha:0];
    [self.slideShow setContentSize:CGSizeMake(640, self.slideShow.frame.size.height)];
    
    [self.slideShow setDidReachPageBlock:^(NSInteger fromPage, NSInteger toPage) {
        if (fromPage - 1 == toPage) {
            [nonRetainSelf showYestoday];
        } else if (fromPage + 1 == toPage) {
            [nonRetainSelf showTomorrow];
        } else {
            // rebuild with currentDate
            self.tripsToday = [self fetchTripsForDate:self.currentDate];
            self.tripsYestoday = [self fetchTripsForDate:[self.currentDate dateBySubtractingDays:1]];
            if (![self.currentDate isToday]) {
                self.tripsTomorrow = [self fetchTripsForDate:[self.currentDate dateByAddingDays:1]];
            } else {
                self.tripsTomorrow = nil;
            }
            [self reloadContent];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
        self.tripsYestoday = self.tripsToday;
        self.tripsToday = self.tripsTomorrow;
        self.tripsTomorrow = [self fetchTripsForDate:[self.currentDate dateByAddingDays:1]];
        
        [self reloadContent];
    }
}

- (void)showYestoday
{
    self.currentDate = [self.currentDate dateBySubtractingDays:1];
    self.tripsTomorrow = self.tripsToday;
    self.tripsToday = self.tripsYestoday;
    self.tripsYestoday = [self fetchTripsForDate:[self.currentDate dateBySubtractingDays:1]];
    
    [self reloadContent];
}

- (NSArray*)fetchTripsForDate:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = self.currentDate;
    }

    NSArray * trips = [[TripsCoreDataManager sharedManager] tripStartFrom:[dateDay dateAtStartOfDay] toDate:[dateDay dateAtEndOfDay]];
    for (TripSummary * sum in trips)
    {
        GPSTurningAnalyzer * turnAnalyzer = [GPSTurningAnalyzer new];
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:sum withAnalyzer:@{@"TurningAnalyzer":turnAnalyzer}];
        
        // update region info
        [[BussinessDataProvider sharedInstance] updateRegionInfo:sum.region_group.start_region force:NO success:^(id) {
            [self.carousel reloadData];
        } failure:nil];
        [[BussinessDataProvider sharedInstance] updateRegionInfo:sum.region_group.end_region force:NO success:^(id) {
            [self.carousel reloadData];
        } failure:nil];
        
        // update traffic light cnt
        if (0 == [sum.traffic_light_tol_cnt integerValue]) {
            [[BussinessDataProvider sharedInstance] updateRoadMarkForTrips:sum ofTurningPoints:[turnAnalyzer.filter featurePoints] success:^(id cnt) {
                [self.carousel reloadData];
                NSArray * allTripView = [self.slideShow allPages];
                [allTripView enumerateObjectsUsingBlock:^(TripTodayView * oneSlide, NSUInteger idx, BOOL *stop) {
                    if (0 == idx) {
                        [oneSlide updateWithTripsToday:self.tripsYestoday];
                    } else if (1 == idx) {
                        [oneSlide updateWithTripsToday:self.tripsToday];
                    } else if (2 == idx) {
                        [oneSlide updateWithTripsToday:self.tripsTomorrow];
                    }
                }];
            } failure:nil];
        }
    }
    return [[trips reverseObjectEnumerator] allObjects];
}

- (void)reloadContent
{
    [self.carousel reloadData];
    [self.carousel scrollToItemAtIndex:0 animated:NO];
    if (self.tripsToday.count > 0) {
        [self.carousel scrollToItemAtIndex:self.tripsToday.count-1 duration:MIN(MAX(self.tripsToday.count/2.0, 0.5), 2.5)];
    }
    self.noResultView.hidden = (self.tripsToday.count > 0);
    [self.switcher setLabelText:[self.currentDate isToday] ? @"今天" : [self.dateFormatter stringFromDate:self.currentDate] forIndex:0];
    
    [self.slideShow resetAllPage];
    
    [self addSlideShow:self.tripsYestoday];
    [self addSlideShow:self.tripsToday];
    if (![self.currentDate isToday]) {
        [self addSlideShow:self.tripsTomorrow];
    }

    [self.slideShow showPageAtIdx:1];
}

- (void)addSlideShow:(NSArray*)tripsArray
{
    TripTodayView * todaySlide = [[[NSBundle mainBundle] loadNibNamed:@"TripTodayView" owner:self options:nil] lastObject];
    todaySlide.backgroundColor = [UIColor clearColor];
    [todaySlide updateWithTripsToday:tripsArray];
    [self.slideShow addPage:todaySlide];
    
    NSUInteger pageIdx = [self.slideShow numberOfPages]-1;
    
    // enter animation
    [self.slideShow addAnimation:[DRDynamicSlideShowAnimation animationForSubview:todaySlide.firstView page:pageIdx keyPath:@"center" toValue:[NSValue valueWithCGPoint:CGPointMake(todaySlide.firstView.center.x+self.slideShow.frame.size.width, todaySlide.firstView.center.y-self.slideShow.frame.size.height)] delay:0]];
    
    [self.slideShow addAnimation:[DRDynamicSlideShowAnimation animationForSubview:todaySlide.thirdView page:pageIdx keyPath:@"center" toValue:[NSValue valueWithCGPoint:CGPointMake(todaySlide.thirdView.center.x+self.slideShow.frame.size.width, todaySlide.secondView.center.y+self.slideShow.frame.size.height)] delay:0]];
    
    // exit animation
    [self.slideShow addAnimation:[DRDynamicSlideShowAnimation animationForSubview:todaySlide.firstView page:pageIdx-1 keyPath:@"transform" fromValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(-0.9)] toValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(0)] delay:0]];
    [self.slideShow addAnimation:[DRDynamicSlideShowAnimation animationForSubview:todaySlide.secondView page:pageIdx-1 keyPath:@"transform" fromValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(-0.9)] toValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(0)] delay:0]];
    [self.slideShow addAnimation:[DRDynamicSlideShowAnimation animationForSubview:todaySlide.thirdView page:pageIdx-1 keyPath:@"transform" fromValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(-0.9)] toValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(0)] delay:0]];
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
