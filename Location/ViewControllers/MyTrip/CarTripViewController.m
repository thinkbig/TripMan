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
#import "TripMonthView.h"
#import "NSDate+Utilities.h"
#import "GPSTurningAnalyzer.h"
#import "DVSwitch.h"
#import "TicketDetailViewController.h"
#import "DaySummary+Fetcher.h"
#import "WeekSummary.h"
#import "MonthSummary.h"
#import "CarTripCell.h"
#import "NSAttributedString+Style.h"
#import "DataDebugPrinter.h"

typedef NS_ENUM(NSUInteger, eTripRange) {
    eTripRangeDay = 0,
    eTripRangeWeek,
    eTripRangeMonth
};

@interface CarTripViewController ()

@property (nonatomic, strong) DaySummary *          sumYestoday;
@property (nonatomic, strong) DaySummary *          sumToday;
@property (nonatomic, strong) DaySummary *          sumTomorrow;
@property (nonatomic, strong) NSDate *              currentDate;

@property (nonatomic, strong) WeekSummary *         sumLastWeek;
@property (nonatomic, strong) WeekSummary *         sumThisWeek;
@property (nonatomic, strong) WeekSummary *         sumNextWeek;
@property (nonatomic, strong) NSDate *              currentWeekDate;

@property (nonatomic, strong) MonthSummary *        sumLastMonth;
@property (nonatomic, strong) MonthSummary *        sumThisMonth;
@property (nonatomic, strong) MonthSummary *        sumNextMonth;
@property (nonatomic, strong) NSDate *              currentMonthDate;

@property (nonatomic, strong) NSDateFormatter *     dateFormatter;
@property (nonatomic, strong) DVSwitch *            switcher;
@property (nonatomic) NSUInteger                    currentIdx;

@end

@implementation CarTripViewController

- (void)internalInit
{
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat: @"MM.dd"];
    [self.dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tripEnd) name:kNotifyTripDidEnd object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) tripEnd
{
    [self rebuildContent:NO];
}

- (NSDate *)currentWeekDate {
    if (nil == _currentWeekDate) {
        _currentWeekDate = [NSDate date];
    }
    return _currentWeekDate;
}

- (NSDate *)currentDate {
    if (nil == _currentDate) {
        _currentDate = [NSDate date];
    }
    return _currentDate;
}

- (NSDate *)currentMonthDate {
    if (nil == _currentMonthDate) {
        _currentMonthDate = [NSDate date];
    }
    return _currentMonthDate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    __block CarTripViewController * weekSelf = self;
    
    // init segment view
    self.switcher = [[DVSwitch alloc] initWithStringsArray:@[@"今天", @"本周", @"本月"]];
    self.switcher.sliderOffset = 2.0;
    self.switcher.cornerRadius = 0;
    self.switcher.backgroundColor = [UIColor clearColor];
    self.switcher.sliderColor = [UIColor clearColor];
    self.switcher.sliderImage = [UIImage imageNamed:@"btn"];
    self.switcher.labelTextColorInsideSlider = [UIColor whiteColor];
    self.switcher.labelTextColorOutsideSlider = [UIColor colorWithWhite:1 alpha:0.54];
    self.switcher.font = [UIFont boldSystemFontOfSize:14];
    [self.switcher setPressedHandler:^(NSUInteger index) {
        NSLog(@"Did press position on first switch at index: %lu", (unsigned long)index);
        weekSelf.currentIdx = index;
    }];
    
    if (nil == self.slideShow) {
        self.slideShow = [[DRDynamicSlideShow alloc] initWithFrame:CGRectMake(0, 0, 320, 210)];
        [self.slideShow setAlpha:0];
        [self.slideShow setContentSize:CGSizeMake(640, self.slideShow.frame.size.height)];
    }
    __block CarTripViewController * nonRetainSelf = self;
    [self.slideShow setDidReachPageBlock:^(NSInteger fromPage, NSInteger toPage) {
        if (1 == nonRetainSelf.currentIdx) {
            if (fromPage - 1 == toPage) {
                [nonRetainSelf showLastWeek];
            } else if (fromPage + 1 == toPage) {
                [nonRetainSelf showNextWeek];
            } else if (fromPage != toPage) {
                // rebuild with currentDate
                [nonRetainSelf rebuildContent:YES];
            }
        } else if (2 == nonRetainSelf.currentIdx) {
            if (fromPage - 1 == toPage) {
                [nonRetainSelf showLastMonth];
            } else if (fromPage + 1 == toPage) {
                [nonRetainSelf showNextMonth];
            } else if (fromPage != toPage) {
                // rebuild with currentDate
                [nonRetainSelf rebuildContent:YES];
            }
        } else {
            if (fromPage - 1 == toPage) {
                [nonRetainSelf showYestoday];
            } else if (fromPage + 1 == toPage) {
                [nonRetainSelf showTomorrow];
            } else if (fromPage != toPage) {
                // rebuild with currentDate
                [nonRetainSelf rebuildContent:YES];
            }
        }
    }];
    
    if (nil == self.carousel) {
        self.carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
        self.carousel.dataSource = self;
        self.carousel.delegate = self;
        self.carousel.type = iCarouselTypeTimeMachine;
        self.carousel.vertical = YES;
        self.carousel.bounceDistance = 0.4;
        self.carousel.decelerationRate = 0.7;
        self.carousel.itemOffset = CGPointMake(0, 15);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.6 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.slideShow setAlpha:1];
    } completion:nil];
    
    [self rebuildContent:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applicationBecomeActive
{
    NSDate * lastResignDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastResignActiveDate];
    if (![lastResignDate isToday]) {
        self.currentIdx = _currentIdx;
    } else {
        [self rebuildContent:NO];
    }
}

- (void)setCurrentIdx:(NSUInteger)currentIdx
{
    _currentIdx = currentIdx;
    NSDate * now = [NSDate date];
    self.currentDate = now;
    self.currentWeekDate = now;
    self.currentMonthDate = now;
    [self.switcher setLabelText:@"今天" forIndex:0];
    [self.switcher setLabelText:@"本周" forIndex:1];
    [self.switcher setLabelText:@"本月" forIndex:2];
    [self rebuildContent:YES];
}

- (void)showTomorrow
{
    if (self.currentDate && ![self.currentDate isToday] && [self.currentDate compare:[NSDate date]] == NSOrderedAscending) {
        self.currentDate = [self.currentDate dateByAddingDays:1];
        self.sumYestoday = self.sumToday;
        self.sumToday = self.sumTomorrow;
        self.sumTomorrow = [self fetchDayTripForDate:[self.currentDate dateByAddingDays:1]];
        
        [self reloadContentOfDay];
    }
}

- (void)showYestoday
{
    self.currentDate = [self.currentDate dateBySubtractingDays:1];
    self.sumTomorrow = self.sumToday;
    self.sumToday = self.sumYestoday;
    self.sumYestoday = [self fetchDayTripForDate:[self.currentDate dateBySubtractingDays:1]];
    
    [self reloadContentOfDay];
}

- (void)showNextWeek
{
    if (self.currentWeekDate && ![self.currentWeekDate isThisWeek] && [self.currentWeekDate compare:[NSDate date]] == NSOrderedAscending) {
        self.currentWeekDate = [self.currentWeekDate dateByAddingDays:7];
        self.sumLastWeek = self.sumThisWeek;
        self.sumThisWeek = self.sumNextWeek;
        self.sumNextWeek = [self fetchWeekTripForDate:[self.currentWeekDate dateByAddingDays:7]];
        
        [self reloadContentOfWeek];
    }
}

- (void)showLastWeek
{
    self.currentWeekDate = [self.currentWeekDate dateBySubtractingDays:7];
    self.sumNextWeek = self.sumThisWeek;
    self.sumThisWeek = self.sumLastWeek;
    self.sumLastWeek = [self fetchWeekTripForDate:[self.currentWeekDate dateBySubtractingDays:7]];
    
    [self reloadContentOfWeek];
}

- (void)showNextMonth
{
    if (self.currentMonthDate && ![self.currentMonthDate isThisMonth] && [self.currentMonthDate compare:[NSDate date]] == NSOrderedAscending) {
        self.currentMonthDate = [self.currentMonthDate dateByAddingMonths:1];
        self.sumLastMonth = self.sumThisMonth;
        self.sumThisMonth = self.sumNextMonth;
        self.sumNextMonth = [self fetchMonthTripForDate:[self.currentMonthDate dateByAddingMonths:1]];
        
        [self reloadContentOfMonth];
    }
}

- (void)showLastMonth
{
    self.currentMonthDate = [self.currentMonthDate dateBySubtractingMonths:1];
    self.sumNextMonth = self.sumThisMonth;
    self.sumThisMonth = self.sumLastMonth;
    self.sumLastMonth = [self fetchMonthTripForDate:[self.currentMonthDate dateBySubtractingMonths:1]];
    
    [self reloadContentOfMonth];
}

- (void)updateDaySumInfo:(DaySummary*)daySum
{
    for (TripSummary * sum in [daySum validTrips])
    {
        // update region info
        [[BussinessDataProvider sharedInstance] updateRegionInfo:sum.region_group.start_region force:NO success:^(id) {
            [self.carousel reloadData];
        } failure:nil];
        [[BussinessDataProvider sharedInstance] updateRegionInfo:sum.region_group.end_region force:NO success:^(id) {
            [self.carousel reloadData];
        } failure:nil];
        
        // update traffic light cnt
        if (0 == [sum.traffic_light_tol_cnt integerValue])
        {
            NSArray * pts = nil;
            NSData * ptsData = sum.turning_info.addi_data;
            if (ptsData) {
                pts = [NSKeyedUnarchiver unarchiveObjectWithData:ptsData];
            }
            if (nil == pts) {
                [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:sum withAnalyzer:nil];
                NSData * ptsData = sum.turning_info.addi_data;
                if (ptsData) {
                    pts = [NSKeyedUnarchiver unarchiveObjectWithData:ptsData];
                }
            }

            [[BussinessDataProvider sharedInstance] updateRoadMarkForTrips:sum ofTurningPoints:pts success:^(id cnt) {
                [self.carousel reloadData];
                [self.slideShow reloadInputViews];
                NSArray * allTripView = [self.slideShow allPages];
                for (id oneSlide in allTripView) {
                    if ([oneSlide isKindOfClass:[TripMonthView class]]) {
                        TripMonthView * oneView = oneSlide;
                        [oneView updateMonth];
                    } else if ([oneSlide isKindOfClass:[TripTodayView class]]) {
                        TripTodayView * oneView = oneSlide;
                        if (1 == _currentIdx) {
                            [oneView updateWeek];
                        } else {
                            [oneView updateDay];
                            [self.carousel reloadData];
                        }
                    }
                }
            } failure:nil];
        }
    }
}

- (DaySummary*)fetchDayTripForDate:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = self.currentDate;
    }

    DaySummary * daySum = [[AnaDbManager deviceDb] daySummaryByDay:dateDay];
    [self updateDaySumInfo:daySum];
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeDaySum:daySum];
    return daySum;
}

- (WeekSummary*)fetchWeekTripForDate:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = self.currentWeekDate;
    }
    
    WeekSummary * weekSum = [[AnaDbManager deviceDb] weekSummaryByDay:dateDay];
    for (DaySummary * daySum in weekSum.all_days)
    {
        [self updateDaySumInfo:daySum];
    }
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeWeekSum:weekSum];
    return weekSum;
}

- (MonthSummary*)fetchMonthTripForDate:(NSDate*)dateDay
{
    if (nil == dateDay) {
        dateDay = self.currentMonthDate;
    }
    
    MonthSummary * monthSum = [[AnaDbManager deviceDb] monthSummaryByDay:dateDay];
    for (DaySummary * daySum in monthSum.all_days)
    {
        [self updateDaySumInfo:daySum];
    }
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeMonthSum:monthSum];
    return monthSum;
}

- (void)rebuildContent:(BOOL)force
{
    if (0 == _currentIdx)
    {
        if (!force && self.sumTomorrow) {
            // means not today
            return;
        }
        [self showLoading];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.sumToday = [self fetchDayTripForDate:self.currentDate];
            self.sumYestoday = [self fetchDayTripForDate:[self.currentDate dateBySubtractingDays:1]];
            if (![self.currentDate isToday]) {
                self.sumTomorrow = [self fetchDayTripForDate:[self.currentDate dateByAddingDays:1]];
            } else {
                self.sumTomorrow = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideLoading];
                [self reloadContentOfDay];
            });
        });
    }
    else if (1 == _currentIdx)
    {
        if (!force && self.sumNextWeek) {
            return;
        }
        [self showLoading];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.sumThisWeek = [self fetchWeekTripForDate:self.currentWeekDate];
            self.sumLastWeek = [self fetchWeekTripForDate:[self.currentWeekDate dateBySubtractingDays:7]];
            if (![self.currentWeekDate isThisWeek]) {
                self.sumNextWeek = [self fetchWeekTripForDate:[self.currentWeekDate dateByAddingDays:7]];
            } else {
                self.sumNextWeek = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideLoading];
                [self reloadContentOfWeek];
            });
        });
    }
    else if (2 == _currentIdx)
    {
        if (!force && self.sumNextWeek) {
            return;
        }
        [self showLoading];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.sumThisMonth = [self fetchMonthTripForDate:self.currentMonthDate];
            self.sumLastMonth = [self fetchMonthTripForDate:[self.currentMonthDate dateBySubtractingMonths:1]];
            if (![self.currentMonthDate isThisMonth]) {
                self.sumNextMonth = [self fetchMonthTripForDate:[self.currentMonthDate dateByAddingMonths:1]];
            } else {
                self.sumNextMonth = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideLoading];
                [self reloadContentOfMonth];
            });
        });
    }
}

- (void)reloadContentOfDay
{
    [self.carousel reloadData];
    [self.carousel scrollToItemAtIndex:0 animated:NO];
    NSArray * tripsToday = [self.sumToday validTrips];
    if (tripsToday > 0) {
        [self.carousel scrollToItemAtIndex:tripsToday.count-1 duration:MIN(MAX(tripsToday.count/2.0, 0.5), 2.5)];
    }
    
    [self.switcher setLabelText:[self.currentDate isToday] ? @"今天" : [self.dateFormatter stringFromDate:self.currentDate] forIndex:0];
    
    [self.slideShow resetAllPage];
    
    [self addSlideShowWithData:self.sumYestoday isWeekSum:NO];
    [self addSlideShowWithData:self.sumToday isWeekSum:NO];
    if (![self.currentDate isToday]) {
        [self addSlideShowWithData:self.sumTomorrow isWeekSum:NO];
    }

    [self.slideShow showPageAtIdx:1];
    
    [self.detailCollection reloadData];
}

- (void)reloadContentOfWeek
{
    [self.slideShow resetAllPage];
    
    [self addSlideShowWithData:self.sumLastWeek isWeekSum:YES];
    [self addSlideShowWithData:self.sumThisWeek isWeekSum:YES];
    if (![self.currentWeekDate isThisWeek]) {
        [self addSlideShowWithData:self.sumNextWeek isWeekSum:YES];
    }
    
    [self.slideShow showPageAtIdx:1];
    
    [self.switcher setLabelText:[self.currentWeekDate isThisWeek] ? @"本周" : [NSString stringWithFormat:@"第%ld周", (long)[self.currentWeekDate weekOfYear]] forIndex:1];
    
    [self.detailCollection reloadData];
}

- (void)addSlideShowWithData:(id)sum isWeekSum:(BOOL)isWeek
{
    TripTodayView * todaySlide = [[[NSBundle mainBundle] loadNibNamed:@"TripTodayView" owner:self options:nil] lastObject];
    todaySlide.backgroundColor = [UIColor clearColor];
    if (isWeek) {
        todaySlide.weekSum = sum;
        [todaySlide updateWeek];
    } else {
        todaySlide.daySum = sum;
        [todaySlide updateDay];
    }
    
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

- (void)reloadContentOfMonth
{
    [self.slideShow resetAllPage];
    
    [self addMonthSlideShowWithData:self.sumLastMonth];
    [self addMonthSlideShowWithData:self.sumThisMonth];
    if (![self.currentMonthDate isThisMonth]) {
        [self addMonthSlideShowWithData:self.sumNextMonth];
    }
    
    [self.slideShow showPageAtIdx:1];
    
    [self.switcher setLabelText:[self.currentMonthDate isThisMonth] ? @"本月" : [NSString stringWithFormat:@"%ld月", (long)[self.currentMonthDate month]] forIndex:2];
    
    [self.detailCollection reloadData];
}

- (void)addMonthSlideShowWithData:(MonthSummary*)sum
{
    TripMonthView * monthSlide = [[[NSBundle mainBundle] loadNibNamed:@"TripMonthView" owner:self options:nil] lastObject];
    monthSlide.backgroundColor = [UIColor clearColor];
    monthSlide.monthSum = sum;
    [monthSlide updateMonth];
    [self.slideShow addPage:monthSlide];
    
    NSUInteger pageIdx = [self.slideShow numberOfPages]-1;
    
    // enter animation
    [self.slideShow addAnimation:[DRDynamicSlideShowAnimation animationForSubview:monthSlide.viewOne page:pageIdx keyPath:@"center" toValue:[NSValue valueWithCGPoint:CGPointMake(monthSlide.viewOne.center.x+monthSlide.frame.size.width, monthSlide.viewOne.center.y-monthSlide.frame.size.height)] delay:0]];
    
    // exit animation
    [self.slideShow addAnimation:[DRDynamicSlideShowAnimation animationForSubview:monthSlide.viewOne page:pageIdx-1 keyPath:@"transform" fromValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(-0.9)] toValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(0)] delay:0]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

+ (UILabel*) geneLabelWithString:(NSString*)str
{
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 16)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:10];
    label.adjustsFontSizeToFitWidth = YES;
    label.text = str;
    return label;
}


#pragma mark iCarouselDelegate

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    DaySummary * userSum = [[AnaDbManager sharedInst] userDaySumForDeviceDaySum:self.sumToday];
    return [self.sumToday validTripCount] + [userSum validTripCount];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    TripTicketView * realView = [[view subviews] lastObject];
    if (nil == realView || ![realView isKindOfClass:[TripTicketView class]]) {
        realView = [[[NSBundle mainBundle] loadNibNamed:@"TripTicketView" owner:self options:nil] lastObject];
        realView.layer.cornerRadius = 5;
        
        view = [[UIView alloc] initWithFrame:realView.bounds];
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowOpacity = 0.5f;
        view.layer.shadowRadius = 5.0f;
        [view addSubview:realView];
    }
    
    NSArray * allArr = [self.sumToday validTrips];
    DaySummary * userSum = [[AnaDbManager sharedInst] userDaySumForDeviceDaySum:self.sumToday];
    if (userSum) {
        allArr = [allArr arrayByAddingObjectsFromArray:[userSum validTrips]];
    }
    NSArray * tripsToday = [allArr sortedArrayUsingComparator:^NSComparisonResult(TripSummary * obj1, TripSummary * obj2) {
        return [obj1.start_date compare:obj2.start_date];
    }];
    [realView updateWithTripSummary:tripsToday[index]];
    
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
    TicketDetailViewController * detailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TicketDetailId"];
    NSArray * allArr = [self.sumToday validTrips];
    DaySummary * userSum = [[AnaDbManager sharedInst] userDaySumForDeviceDaySum:self.sumToday];
    if (userSum) {
        allArr = [allArr arrayByAddingObjectsFromArray:[userSum validTrips]];
    }
    NSArray * tripsToday = [allArr sortedArrayUsingComparator:^NSComparisonResult(TripSummary * obj1, TripSummary * obj2) {
        return [obj1.start_date compare:obj2.start_date];
    }];
    detailVC.tripSum = tripsToday[index];
    
    //NSString * str = [DataDebugPrinter jsonTripSummary:detailVC.tripSum];
    
    [self.navigationController pushViewController:detailVC animated:YES];
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (0 == _currentIdx) {
        return 2;
    } else if (1 == _currentIdx) {
        return 5;
    } else if (2 == _currentIdx) {
        return 4;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (0 == _currentIdx)
    {
        if (0 == indexPath.row) {
            CarTripSliderCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SliderCellId" forIndexPath:indexPath];
            CGSize contentSz = self.slideShow.contentSize;
            contentSz.height = [self collectionView:collectionView layout:nil sizeForItemAtIndexPath:indexPath].height;
            self.slideShow.contentSize = contentSz;
            [realCell setSliderView:self.slideShow];
            
            cell = realCell;
        } else if (1 == indexPath.row) {
            CarTripCarouselCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"iCarouselId" forIndexPath:indexPath];
            [realCell setCarouselView:self.carousel];
            [realCell showNoResult:(0 == [self.sumToday validTripCount])];
            
            cell = realCell;
        }
    }
    else if (1 == _currentIdx)
    {
        if (0 == indexPath.row)
        {
            CarTripSliderCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SliderCellId" forIndexPath:indexPath];
            CGSize contentSz = self.slideShow.contentSize;
            contentSz.height = [self collectionView:collectionView layout:nil sizeForItemAtIndexPath:indexPath].height;
            self.slideShow.contentSize = contentSz;
            [realCell setSliderView:self.slideShow];
            
            cell = realCell;
        } else if (1 == indexPath.row) {
            NSMutableDictionary * distDict = [NSMutableDictionary dictionary];
            NSMutableDictionary * duringDict = [NSMutableDictionary dictionary];
            for (DaySummary * daySum in self.sumThisWeek.all_days) {
                NSNumber * weekDay = @([daySum.date_day weekday]);
                [distDict setObject:daySum.total_dist forKey:weekDay];
                [duringDict setObject:daySum.total_during forKey:weekDay];
            }
            WeekSummary * userSum = [[AnaDbManager sharedInst] userWeekSumForDeviceWeekSum:self.sumThisWeek];
            for (DaySummary * daySum in userSum.all_days) {
                NSNumber * weekDay = @([daySum.date_day weekday]);
                CGFloat oldDist = [distDict[weekDay] floatValue] + [daySum.total_dist floatValue];
                CGFloat oldDuring = [duringDict[weekDay] floatValue] + [daySum.total_during floatValue];
                distDict[weekDay] = @(oldDist);
                duringDict[weekDay] = @(oldDuring);
            }
            
            WeekSumCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"weekSumCellId" forIndexPath:indexPath];
            realCell.distBarView.waitToUpdate = YES;
            [realCell.distBarView setAlgorithm:^CGFloat(CGFloat x) {
                return [distDict[@(x+1)] floatValue]/1000.0;
            } numberOfPoints:7 withGeneDetailBlock:^UILabel *(CGFloat y) {
                return [[self class] geneLabelWithString:[NSString stringWithFormat:@"%.f", y]];
            }];
            
            realCell.distBarView.coorDelegate = realCell.xCoorBarView;
            
            [realCell.duringBarView setAlgorithm:^CGFloat(CGFloat x) {
                return [duringDict[@(x+1)] floatValue]/60.0;
            } numberOfPoints:7 withGeneDetailBlock:^UILabel *(CGFloat y) {
                return [[self class] geneLabelWithString:[NSString stringWithFormat:@"%.f", y]];
            }];
            
            realCell.duringBarView.waitToUpdate = YES;
            [realCell animWithDelay:0.1];

            cell = realCell;
        } else if (2 == indexPath.row) {
            NSMutableDictionary * avgDict = [NSMutableDictionary dictionary];
            NSMutableDictionary * maxDict = [NSMutableDictionary dictionary];
            CGFloat maxSpeed = 0;
            for (DaySummary * daySum in self.sumThisWeek.all_days) {
                NSNumber * weekDay = @([daySum.date_day weekday]);
                [maxDict setObject:daySum.max_speed forKey:weekDay];
                [avgDict setObject:daySum.avg_speed forKey:weekDay];
                maxSpeed = MAX(maxSpeed, [daySum.max_speed floatValue]);
            }
            WeekSummary * userSum = [[AnaDbManager sharedInst] userWeekSumForDeviceWeekSum:self.sumThisWeek];
            for (DaySummary * daySum in userSum.all_days) {
                NSNumber * weekDay = @([daySum.date_day weekday]);
                CGFloat oldMaxSpeed = MAX([maxDict[weekDay] floatValue], [daySum.max_speed floatValue]);
                CGFloat oldAvgSpeed = [avgDict[weekDay] floatValue];
                if (avgDict[weekDay]) {
                    oldAvgSpeed = ([avgDict[weekDay] floatValue] + [daySum.avg_speed floatValue])/2.0;
                } else {
                    oldAvgSpeed = [daySum.avg_speed floatValue];
                }
                maxDict[weekDay] = @(oldMaxSpeed);
                avgDict[weekDay] = @(oldAvgSpeed);
                maxSpeed = MAX(maxSpeed, oldMaxSpeed);
            }
            
            maxSpeed *= 3.6;
            if (0 == maxSpeed) {
                maxSpeed = 1;
            }
            
            WeekSpeedCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"weekSpeedCellId" forIndexPath:indexPath];
            realCell.maxSpeedView.waitToUpdate = YES;
            realCell.maxSpeedView.valueRanges = MPMakeGraphValuesRange(0, maxSpeed);
            [realCell.maxSpeedView setAlgorithm:^CGFloat(CGFloat x) {
                return [maxDict[@(x+1)] floatValue]*3.6;
            } numberOfPoints:7 withGeneDetailBlock:^UILabel *(CGFloat y) {
                return [[self class] geneLabelWithString:[NSString stringWithFormat:@"%.f", y]];
            }];
            
            realCell.avgSpeedView.waitToUpdate = YES;
            realCell.avgSpeedView.valueRanges = MPMakeGraphValuesRange(0, maxSpeed);
            [realCell.avgSpeedView setAlgorithm:^CGFloat(CGFloat x) {
                return [avgDict[@(x+1)] floatValue]*3.6;
            } numberOfPoints:7 withGeneDetailBlock:^UILabel *(CGFloat y) {
                UILabel * label = [[self class] geneLabelWithString:(0==y ? @"" : [NSString stringWithFormat:@"%.f", y])];
                label.textColor = [UIColor darkTextColor];
                return label;
            }];
            
            [realCell animWithDelay:0.1];
            
            cell = realCell;
        } else if (3 == indexPath.row) {
            NSMutableDictionary * jamDuringDict = [NSMutableDictionary dictionary];
            NSMutableDictionary * secondDict = [NSMutableDictionary dictionary];
            for (DaySummary * daySum in self.sumThisWeek.all_days) {
                NSNumber * weekDay = @([daySum.date_day weekday]);
                [jamDuringDict setObject:daySum.jam_during forKey:weekDay];
                [secondDict setObject:daySum.traffic_heavy_jam_cnt forKey:weekDay];
            }
            WeekSummary * userSum = [[AnaDbManager sharedInst] userWeekSumForDeviceWeekSum:self.sumThisWeek];
            for (DaySummary * daySum in userSum.all_days) {
                NSNumber * weekDay = @([daySum.date_day weekday]);
                CGFloat oldJamDuring = [jamDuringDict[weekDay] floatValue] + [daySum.jam_during floatValue];
                NSInteger oldJamCnt = [secondDict[weekDay] integerValue] + [daySum.traffic_heavy_jam_cnt integerValue];
                jamDuringDict[weekDay] = @(oldJamDuring);
                secondDict[weekDay] = @(oldJamCnt);
            }
            
            WeekJamCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"weekJamCellId" forIndexPath:indexPath];
            realCell.jamDuringView.waitToUpdate = YES;
            [realCell.jamDuringView setAlgorithm:^CGFloat(CGFloat x) {
                return [jamDuringDict[@(x+1)] floatValue]/60.0;
            } numberOfPoints:7 withGeneDetailBlock:^UILabel *(CGFloat y) {
                return [[self class] geneLabelWithString:[NSString stringWithFormat:@"%.f", y]];
            }];
            
            realCell.jamCountView.waitToUpdate = YES;
            [realCell.jamCountView setAlgorithm:^CGFloat(CGFloat x) {
                return [secondDict[@(x+1)] integerValue];
            } numberOfPoints:7 withGeneDetailBlock:^UILabel *(CGFloat y) {
                return [[self class] geneLabelWithString:[NSString stringWithFormat:@"%.f", y]];
            }];
            
            [realCell animWithDelay:0.1];
            
            cell = realCell;
        } else if (4 == indexPath.row) {
            NSMutableDictionary * waitingDict = [NSMutableDictionary dictionary];
            NSMutableDictionary * lightCntDict = [NSMutableDictionary dictionary];
            for (DaySummary * daySum in self.sumThisWeek.all_days) {
                NSNumber * weekDay = @([daySum.date_day weekday]);
                [waitingDict setObject:daySum.traffic_light_waiting forKey:weekDay];
                [lightCntDict setObject:daySum.traffic_light_jam_cnt forKey:weekDay];
            }
            WeekSummary * userSum = [[AnaDbManager sharedInst] userWeekSumForDeviceWeekSum:self.sumThisWeek];
            for (DaySummary * daySum in userSum.all_days) {
                NSNumber * weekDay = @([daySum.date_day weekday]);
                CGFloat oldWait = [waitingDict[weekDay] floatValue] + [daySum.traffic_light_waiting floatValue];
                NSInteger oldLightCnt = [lightCntDict[weekDay] integerValue] + [daySum.traffic_light_jam_cnt integerValue];
                waitingDict[weekDay] = @(oldWait);
                lightCntDict[weekDay] = @(oldLightCnt);
            }
            
            WeekTrafficLightCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"weekTrafficLightCellId" forIndexPath:indexPath];
            realCell.lightDuringView.waitToUpdate = YES;
            [realCell.lightDuringView setAlgorithm:^CGFloat(CGFloat x) {
                return [waitingDict[@(x+1)] floatValue]/60.0;
            } numberOfPoints:7 withGeneDetailBlock:^UILabel *(CGFloat y) {
                return [[self class] geneLabelWithString:[NSString stringWithFormat:@"%.1f", y]];
            }];
            
            realCell.lightCountView.waitToUpdate = YES;
            [realCell.lightCountView setAlgorithm:^CGFloat(CGFloat x) {
                return [lightCntDict[@(x+1)] integerValue];
            } numberOfPoints:7 withGeneDetailBlock:^UILabel *(CGFloat y) {
                return [[self class] geneLabelWithString:[NSString stringWithFormat:@"%.f", y]];
            }];
            
            [realCell animWithDelay:0.1];
            
            cell = realCell;
        }
    }
    else if (2 == _currentIdx)
    {
        if (0 == indexPath.row) {
            CarTripSliderCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SliderCellId" forIndexPath:indexPath];
            CGSize contentSz = self.slideShow.contentSize;
            contentSz.height = [self collectionView:collectionView layout:nil sizeForItemAtIndexPath:indexPath].height;
            self.slideShow.contentSize = contentSz;
            [realCell setSliderView:self.slideShow];
            
            cell = realCell;
        } else if (1 == indexPath.row) {
            MonthBestCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"monthBestCellId" forIndexPath:indexPath];
            realCell.titlePrev.text = @"本月最长行驶：";
            NSString * valStr = [NSString stringWithFormat:@"%.f", [self.sumThisMonth.trip_most_dist.total_dist floatValue]/1000.0];
            realCell.titleContent.attributedText = [NSAttributedString stringWithNumber:valStr font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"km" font:[UIFont boldSystemFontOfSize:12] color:[UIColor whiteColor]];
            [realCell updateWithTripSum:[[AnaDbManager sharedInst] tripMostDistForMonthSum:self.sumThisMonth]];
            
            cell = realCell;
        } else if (2 == indexPath.row) {
            MonthBestCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"monthBestCellId" forIndexPath:indexPath];
            realCell.titlePrev.text = @"本月最久行驶：";
            NSString * valStr = [NSString stringWithFormat:@"%.f", [self.sumThisMonth.trip_most_during.total_during floatValue]/60.0];
            realCell.titleContent.attributedText = [NSAttributedString stringWithNumber:valStr font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"min" font:[UIFont boldSystemFontOfSize:12] color:[UIColor whiteColor]];
            [realCell updateWithTripSum:[[AnaDbManager sharedInst] tripMostDuringForMonthSum:self.sumThisMonth]];
            
            cell = realCell;
        } else if (3 == indexPath.row) {
            MonthBestCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"monthBestCellId" forIndexPath:indexPath];
            realCell.titlePrev.text = @"本月最久拥堵：";
            NSString * valStr = [NSString stringWithFormat:@"%.f", [self.sumThisMonth.trip_most_jam_during.traffic_jam_during floatValue]/60.0];
            realCell.titleContent.attributedText = [NSAttributedString stringWithNumber:valStr font:[UIFont boldSystemFontOfSize:24] color:[UIColor whiteColor] andUnit:@"min" font:[UIFont boldSystemFontOfSize:12] color:[UIColor whiteColor]];
            [realCell updateWithTripSum:[[AnaDbManager sharedInst] tripMostJamDuringForMonthSum:self.sumThisMonth]];
            
            cell = realCell;
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView* reusableView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        CarTripHeader* header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CarTripHeaderId" forIndexPath:indexPath];
        [header addSegmentView:self.switcher];
        reusableView = header;
    }
    
    return reusableView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == _currentIdx) {
        if (0 == indexPath.row) {
            return CGSizeMake(320.f, 210.f);
        } else if(1 == indexPath.row) {
            return CGSizeMake(320.f, 240.f);
        }
    } else if (1 == _currentIdx) {
        if (0 == indexPath.row) {
            return CGSizeMake(320.f, 210.f);
        } else if(1 == indexPath.row) {
            return CGSizeMake(320.f, 300.f);
        } else if(2 == indexPath.row) {
            return CGSizeMake(320.f, 200.f);
        } else if(3 == indexPath.row) {
            return CGSizeMake(320.f, 240.f);
        } else if(4 == indexPath.row) {
            return CGSizeMake(320.f, 270.f);
        }
    } else if (2 == _currentIdx) {
        if (0 == indexPath.row) {
            return CGSizeMake(320.f, 90.f);
        } else if (_currentIdx >= 1 && _currentIdx <= 3) {
            return CGSizeMake(320.f, 215.f);
        }
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0.f, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
{
    if (0 == section) {
        return CGSizeMake(320, 70);
    }
    return CGSizeZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (2 == _currentIdx) {
        if (indexPath.row >= 1 && indexPath.row <= 3) {
            TicketDetailViewController * detailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TicketDetailId"];
            if (1 == indexPath.row) {
                detailVC.tripSum = self.sumThisMonth.trip_most_dist;
            } else if (2 == indexPath.row) {
                detailVC.tripSum = self.sumThisMonth.trip_most_during;
            } else {
                detailVC.tripSum = self.sumThisMonth.trip_most_jam_during;
            }
            [self.navigationController pushViewController:detailVC animated:YES];
        }
    }
}

@end
