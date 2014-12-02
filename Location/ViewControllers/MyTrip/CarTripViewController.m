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
#import "TicketDetailViewController.h"
#import "CarTripCell.h"

typedef NS_ENUM(NSUInteger, eTripRange) {
    eTripRangeDay = 0,
    eTripRangeWeek,
    eTripRangeMonth
};

@interface CarTripViewController ()

@property (nonatomic, strong) NSArray *             tripsYestoday;
@property (nonatomic, strong) NSArray *             tripsToday;
@property (nonatomic, strong) NSArray *             tripsTomorrow;
@property (nonatomic, strong) NSDate *              currentDate;

@property (nonatomic, strong) NSArray *             tripsLastWeek;
@property (nonatomic, strong) NSArray *             tripsThisWeek;
@property (nonatomic, strong) NSArray *             tripsNextWeek;
@property (nonatomic, strong) NSDate *              currentWeekDate;
@property (nonatomic, strong) NSMutableDictionary * tripsDayWithinCurrentWeek;

@property (nonatomic, strong) NSDateFormatter *     dateFormatter;
@property (nonatomic, strong) NSDateFormatter *     dateFormatterMonth;
@property (nonatomic, strong) DVSwitch *            switcher;
@property (nonatomic) NSUInteger                    currentIdx;

@end

@implementation CarTripViewController

- (void)internalInit
{
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat: @"MM.dd"];
    [self.dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    
    self.dateFormatterMonth = [[NSDateFormatter alloc] init];
    [self.dateFormatterMonth setDateFormat: @"MM"];
    [self.dateFormatterMonth setTimeZone:[NSTimeZone localTimeZone]];
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

//- (NSMutableDictionary *)tripsDayWithinCurrentWeek
//{
//    
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    __block CarTripViewController * weekSelf = self;
    
    // init segment view
    self.switcher = [[DVSwitch alloc] initWithStringsArray:@[@"今天", @"本周", @"本月"]];
    self.switcher.sliderOffset = 2.0;
    self.switcher.cornerRadius = 14;
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
                [nonRetainSelf rebuildContent];
            }
        } else {
            if (fromPage - 1 == toPage) {
                [nonRetainSelf showYestoday];
            } else if (fromPage + 1 == toPage) {
                [nonRetainSelf showTomorrow];
            } else if (fromPage != toPage) {
                // rebuild with currentDate
                [nonRetainSelf rebuildContent];
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
    
    [self rebuildContent];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.6 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.slideShow setAlpha:1];
    } completion:nil];
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

- (void)setCurrentIdx:(NSUInteger)currentIdx
{
    if (currentIdx != _currentIdx) {
        _currentIdx = currentIdx;
        [self rebuildContent];
    }
}

- (void)showTomorrow
{
    if (self.currentDate && ![self.currentDate isToday] && [self.currentDate compare:[NSDate date]] == NSOrderedAscending) {
        self.currentDate = [self.currentDate dateByAddingDays:1];
        self.tripsYestoday = self.tripsToday;
        self.tripsToday = self.tripsTomorrow;
        self.tripsTomorrow = [self fetchTripsForDate:[self.currentDate dateByAddingDays:1] withRange:eTripRangeDay];
        
        [self reloadContentOfDay];
    }
}

- (void)showYestoday
{
    self.currentDate = [self.currentDate dateBySubtractingDays:1];
    self.tripsTomorrow = self.tripsToday;
    self.tripsToday = self.tripsYestoday;
    self.tripsYestoday = [self fetchTripsForDate:[self.currentDate dateBySubtractingDays:1] withRange:eTripRangeDay];
    
    [self reloadContentOfDay];
}

- (void)showNextWeek
{
    if (self.currentWeekDate && ![self.currentWeekDate isThisWeek] && [self.currentWeekDate compare:[NSDate date]] == NSOrderedAscending) {
        self.currentWeekDate = [self.currentWeekDate dateByAddingDays:7];
        self.tripsLastWeek = self.tripsThisWeek;
        self.tripsThisWeek = self.tripsNextWeek;
        self.tripsNextWeek = [self fetchTripsForDate:[self.currentWeekDate dateByAddingDays:7] withRange:eTripRangeWeek];
        
        [self reloadContentOfWeek];
    }
}

- (void)showLastWeek
{
    self.currentWeekDate = [self.currentWeekDate dateBySubtractingDays:7];
    self.tripsNextWeek = self.tripsThisWeek;
    self.tripsThisWeek = self.tripsLastWeek;
    self.tripsLastWeek = [self fetchTripsForDate:[self.currentWeekDate dateBySubtractingDays:7] withRange:eTripRangeWeek];
    
    [self reloadContentOfWeek];
}

- (NSArray*)fetchTripsForDate:(NSDate*)dateDay withRange:(eTripRange)range
{
    if (nil == dateDay) {
        if (eTripRangeWeek == range) {
            dateDay = self.currentWeekDate;
        } else {
            dateDay = self.currentDate;
        }
    }

    NSArray * trips = nil;
    if (eTripRangeWeek == range) {
        trips = [[TripsCoreDataManager sharedManager] tripStartFrom:[dateDay dateAtStartOfWeek] toDate:[dateDay dateAtEndOfWeek]];
    } else {
        trips = [[TripsCoreDataManager sharedManager] tripStartFrom:[dateDay dateAtStartOfDay] toDate:[dateDay dateAtEndOfDay]];
    }
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
                [self.slideShow reloadInputViews];
//                NSArray * allTripView = [self.slideShow allPages];
//                [allTripView enumerateObjectsUsingBlock:^(TripTodayView * oneSlide, NSUInteger idx, BOOL *stop) {
//                    if (0 == idx) {
//                        [oneSlide updateWithTripsToday:self.tripsYestoday];
//                    } else if (1 == idx) {
//                        [oneSlide updateWithTripsToday:self.tripsToday];
//                    } else if (2 == idx) {
//                        [oneSlide updateWithTripsToday:self.tripsTomorrow];
//                    }
//                }];
            } failure:nil];
        }
    }
    return [[trips reverseObjectEnumerator] allObjects];
}

- (void)rebuildContent
{
    [self.detailCollection reloadData];
    
    if (0 == _currentIdx)
    {
        self.tripsToday = [self fetchTripsForDate:self.currentDate withRange:eTripRangeDay];
        self.tripsYestoday = [self fetchTripsForDate:[self.currentDate dateBySubtractingDays:1] withRange:eTripRangeDay];
        if (![self.currentDate isToday]) {
            self.tripsTomorrow = [self fetchTripsForDate:[self.currentDate dateByAddingDays:1] withRange:eTripRangeDay];
        } else {
            self.tripsTomorrow = nil;
        }
        
        [self reloadContentOfDay];
    }
    else if (1 == _currentIdx)
    {
        self.tripsThisWeek = [self fetchTripsForDate:self.currentWeekDate withRange:eTripRangeWeek];
        self.tripsLastWeek = [self fetchTripsForDate:[self.currentWeekDate dateBySubtractingDays:7] withRange:eTripRangeWeek];
        if (![self.currentDate isThisWeek]) {
            self.tripsNextWeek = [self fetchTripsForDate:[self.currentWeekDate dateByAddingDays:7] withRange:eTripRangeWeek];
        } else {
            self.tripsNextWeek = nil;
        }
        
        [self reloadContentOfWeek];
    }
}

- (void)reloadContentOfDay
{
    [self.carousel reloadData];
    [self.carousel scrollToItemAtIndex:0 animated:NO];
    if (self.tripsToday.count > 0) {
        [self.carousel scrollToItemAtIndex:self.tripsToday.count-1 duration:MIN(MAX(self.tripsToday.count/2.0, 0.5), 2.5)];
    }
    
    [self.switcher setLabelText:[self.currentDate isToday] ? @"今天" : [self.dateFormatter stringFromDate:self.currentDate] forIndex:0];
    
    [self.slideShow resetAllPage];
    
    [self addSlideShow:self.tripsYestoday];
    [self addSlideShow:self.tripsToday];
    if (![self.currentDate isToday]) {
        [self addSlideShow:self.tripsTomorrow];
    }

    [self.slideShow showPageAtIdx:1];
    
    [self.detailCollection reloadInputViews];
}

- (void)reloadContentOfWeek
{
    [self.slideShow resetAllPage];
    
    [self addSlideShow:self.tripsLastWeek];
    [self addSlideShow:self.tripsThisWeek];
    if (![self.currentWeekDate isThisWeek]) {
        [self addSlideShow:self.tripsNextWeek];
    }
    
    [self.slideShow showPageAtIdx:1];
    
    [self.switcher setLabelText:[self.currentWeekDate isThisWeek] ? @"本周" : [NSString stringWithFormat:@"第%ld周", (long)[self.currentWeekDate weekOfYear]] forIndex:1];
    
    [self.detailCollection reloadInputViews];
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
    TicketDetailViewController * detailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TicketDetailId"];
    detailVC.tripSum = self.tripsToday[index];
    [self.navigationController pushViewController:detailVC animated:YES];
    
//    MapDisplayViewController * mapVC = [[UIStoryboard storyboardWithName:@"Debug" bundle:nil] instantiateViewControllerWithIdentifier:@"MapDisplayView"];
//    mapVC.tripSum = self.tripsToday[index];
//    [self presentViewController:mapVC animated:YES completion:nil];
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
        return 2;
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
            [realCell setSliderView:self.slideShow];
            
            cell = realCell;
        } else if (1 == indexPath.row) {
            CarTripCarouselCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"iCarouselId" forIndexPath:indexPath];
            [realCell setCarouselView:self.carousel];
            [realCell showNoResult:(0 == self.tripsToday.count)];
            
            cell = realCell;
        }
    }
    else if (1 == _currentIdx)
    {
        if (0 == indexPath.row) {
            CarTripSliderCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SliderCellId" forIndexPath:indexPath];
            [realCell setSliderView:self.slideShow];
            
            cell = realCell;
        } else if (1 == indexPath.row) {
            WeekSumCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"weekSumCellId" forIndexPath:indexPath];
            realCell.distBarView.waitToUpdate = YES;
//            graph5.waitToUpdate = YES;
//            graph5.detailView = (UIView <MPDetailView> *)[self customDetailView];
//            [graph5 setAlgorithm:^CGFloat(CGFloat x) {
//                return tan(x);
//            } numberOfPoints:8];
//            graph5.graphColor = [UIColor colorWithRed:0.120 green:0.806 blue:0.157 alpha:1.000];
//            
//            coorX.coorStrArray = @[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h"];
//            graph5.coorDelegate = coorX;
            
            cell = realCell;
        }
    }
    
    return cell;
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
            return CGSizeMake(320.f, 260.f);
        }
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if (0 == section) {
        return 10.f;
    }
    return 1.0f;
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

@end
