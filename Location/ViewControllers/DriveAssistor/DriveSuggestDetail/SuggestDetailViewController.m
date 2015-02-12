//
//  SuggestDetailViewController.m
//  TripMan
//
//  Created by taq on 11/19/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "SuggestDetailViewController.h"
#import "SuggestOverLayerCollectionViewController.h"
#import "GeoTransformer.h"
#import "TSPair.h"
#import "GPSOffTimeFilter.h"
#import "BaiduHelper.h"
#import "UIImage+Rotate.h"

#define OVER_HEADER_HEIGHT      114

@interface RouteAnnotation : BMKPointAnnotation

@property (nonatomic) int type;         // 0:起点 1：终点 2:节点 3:途经poi点
@property (nonatomic) int degree;

@end

@implementation RouteAnnotation

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface SuggestDetailViewController ()

@property (nonatomic, strong) SuggestOverLayerCollectionViewController *    overLayerVC;
@property (nonatomic, strong) NSArray *         gpsLogs;
@property (nonatomic, strong) NSArray *         jamIndex;
@property (nonatomic) CGPoint                   lastTouchLoc;
@property (nonatomic) BOOL                      isOpen;
@property (nonatomic, strong) BaiduHelper *     bdHelper;

@end

@implementation SuggestDetailViewController

- (void)internalInit {
    [super internalInit];
    self.bdHelper = [BaiduHelper new];
}

- (void)dealloc
{
    [self.overLayerVC.collectionView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.rootScrollView.scrollEnabled = NO;
    CGRect scrollFrame = self.rootScrollView.bounds;
    // add header and content
    if (nil == self.mapView) {
        self.mapView = [[BMKMapView alloc] initWithFrame:scrollFrame];
        self.mapView.delegate = self;
        self.mapView.zoomEnabled = YES;
        self.mapView.scrollEnabled = YES;
        [self.rootScrollView addSubview:self.mapView withAcceleration:CGPointMake(0.0, 0.5)];
    }
    self.mapView.showsUserLocation = YES;
    
    if (nil == self.overLayerVC) {
        self.overLayerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestOverLay"];
        scrollFrame.origin.y = (scrollFrame.size.height - OVER_HEADER_HEIGHT);
        self.overLayerVC.view.frame = scrollFrame;
        self.overLayerVC.collectionView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main_bg"]];
        [self.rootScrollView addSubview:self.overLayerVC.view];
    }
    CGSize contentSize = self.rootScrollView.frame.size;
    contentSize.height = CGRectGetMaxY(scrollFrame);
    self.rootScrollView.contentSize = contentSize;
    
    [self.overLayerVC.collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    [self updateTripInfo];
    [self updateRouteView:[GPSOffTimeFilter smoothGPSData:_gpsLogs iteratorCnt:3]];
    
    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOverLayer:)];
    [self.overLayerVC.collectionView addGestureRecognizer:panGesture];
    
    __block CGPoint offset = self.rootScrollView.contentOffset;
    offset.y = self.rootScrollView.height - OVER_HEADER_HEIGHT;
    [self.rootScrollView setContentOffset:offset animated:NO];
    [UIView animateWithDuration:1.0 delay:0.6 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        offset.y = 0.f;
        [self.rootScrollView setContentOffset:offset animated:NO];
    } completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)panOverLayer:(UIPanGestureRecognizer*)panGesture
{
    CGPoint loc = [panGesture translationInView:self.rootScrollView];
    UIGestureRecognizerState stat = panGesture.state;
    CGPoint offset = self.rootScrollView.contentOffset;
    if (UIGestureRecognizerStateBegan == stat) {
        self.lastTouchLoc = loc;
        self.isOpen = offset.y == 0 ? NO : YES;
    } else {
        offset.y -= loc.y-self.lastTouchLoc.y;
        self.rootScrollView.contentOffset = offset;
        self.lastTouchLoc = loc;
        if (UIGestureRecognizerStateEnded == stat) {
            CGFloat thresOffset = self.rootScrollView.height - OVER_HEADER_HEIGHT;
            CGFloat maxOffset = self.overLayerVC.collectionView.height - OVER_HEADER_HEIGHT;
            CGFloat halfThres = !self.isOpen ? thresOffset/3.0 : 2.0*thresOffset/3.0;
            if (offset.y < halfThres) {
                offset.y = 0;
            } else if (offset.y >= maxOffset) {
                offset.y = maxOffset;
            } else if (offset.y >= halfThres && offset.y < thresOffset) {
                offset.y = thresOffset;
            }
            [self.rootScrollView setContentOffset:offset animated:YES];
        }
    }
}

- (void)updateTripInfo
{
    if (self.tripSum)
    {
        NSMutableArray * logs = [NSMutableArray array];
        
        GPSLogItem * stLog = [[GPSLogItem alloc] initWithParkingRegion:self.tripSum.region_group.start_region];
        stLog.timestamp = self.tripSum.start_date;
        [logs addObject:stLog];
        
        NSArray * logArr = [[GPSLogger sharedLogger].dbLogger selectLogFrom:self.tripSum.start_date toDate:self.tripSum.end_date offset:0 limit:0];
        [logs addObjectsFromArray:logArr];
        self.gpsLogs = logs;
        
        [self.mapView reloadInputViews];
        
        self.overLayerVC.tripSum = self.tripSum;
        [self.overLayerVC.collectionView reloadInputViews];
    }
}

-(void) updateRouteView:(NSArray*)gpsLog
{
    [self.mapView removeOverlays:self.mapView.overlays];
    
    if (gpsLog.count > 1)
    {
        NSArray * jamArr =  [[self.tripSum.traffic_jams allObjects] sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(TrafficJam * obj1, TrafficJam * obj2) {
            return [obj1.start_date compare:obj2.start_date];
        }];
        
        NSMutableArray * jamLogArr = [NSMutableArray arrayWithCapacity:jamArr.count];
        NSInteger rawJamIdx = 0;
        TrafficJam * curJam = nil;
        if (jamArr.count > 0) {
            curJam = jamArr[0];
        }
        GPSLogItem * firstLog = gpsLog[0];
        NSTimeInterval lastDuring = fabs([firstLog.timestamp timeIntervalSinceDate:curJam.start_date]);
        TSPair * pair = nil;
        for (NSInteger i = 1; i < gpsLog.count; i++)
        {
            if (nil == curJam) {
                break;
            }
            GPSLogItem * curLog = gpsLog[i];
            if (nil == pair) {
                NSTimeInterval during = fabs([curLog.timestamp timeIntervalSinceDate:curJam.start_date]);
                if (during >= lastDuring) {
                    pair = TSPairMake(@(i-1), nil, nil);
                    lastDuring = fabs([curLog.timestamp timeIntervalSinceDate:curJam.end_date]);
                } else {
                    lastDuring = during;
                }
            } else {
                NSTimeInterval during = fabs([curLog.timestamp timeIntervalSinceDate:curJam.end_date]);
                if (during >= lastDuring) {
                    pair.second = @(i-1);
                    [jamLogArr addObject:pair];
                    pair = nil;
                    rawJamIdx++;
                    if (rawJamIdx < jamArr.count) {
                        curJam = jamArr[rawJamIdx];
                    } else {
                        break;
                    }
                    lastDuring = fabs([curLog.timestamp timeIntervalSinceDate:curJam.start_date]);
                } else {
                    lastDuring = during;
                }
            }
        }
        
        BMKCoordinateRegion region;
        
        CLLocationDegrees maxLat = -90;
        CLLocationDegrees maxLon = -180;
        CLLocationDegrees minLat = 90;
        CLLocationDegrees minLon = 180;
        
        BMKMapPoint * pointsToUse = new BMKMapPoint[gpsLog.count];
        int realCnt = 0;
        BOOL isJam = NO;
        NSInteger stJamIdx = -1;
        NSInteger edJamIdx = -1;
        NSInteger jamIdx = 0;
        if (jamLogArr.count > 0) {
            TSPair * curJamPair = jamLogArr[jamIdx];
            stJamIdx = [curJamPair.first integerValue];
            edJamIdx = [curJamPair.second integerValue];
        }
        for (int i = 0; i < gpsLog.count; i++)
        {
            GPSLogItem * item = gpsLog[i];
            
            if ([item.horizontalAccuracy doubleValue] > 1000) {
                continue;
            }
            
            CLLocationCoordinate2D coords;
            coords.latitude = [item.latitude doubleValue];
            coords.longitude = [item.longitude doubleValue];
            CLLocationCoordinate2D regionCoord = [GeoTransformer earth2Baidu:coords];
            BMKMapPoint marsCoords = BMKMapPointForCoordinate(regionCoord);
            
            if (i == 0) {
                RouteAnnotation* item = [[RouteAnnotation alloc] init];
                item.coordinate = regionCoord;
                item.title = @"起点";
                item.type = 0;
                [_mapView addAnnotation:item];
            } else if (i == gpsLog.count-1) {
                RouteAnnotation* item = [[RouteAnnotation alloc] init];
                item.coordinate = regionCoord;
                item.title = @"终点";
                item.type = 1;
                [_mapView addAnnotation:item];
            }
            
            if(regionCoord.latitude > maxLat)
                maxLat = regionCoord.latitude;
            if(regionCoord.latitude < minLat)
                minLat = regionCoord.latitude;
            if(regionCoord.longitude > maxLon)
                maxLon = regionCoord.longitude;
            if(regionCoord.longitude < minLon)
                minLon = regionCoord.longitude;
            
            // travel route and traffic jam route
            pointsToUse[realCnt++] = marsCoords;
            if (!isJam && i >= stJamIdx && i <= edJamIdx) {
                BMKPolyline * lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:realCnt];
                lineOne.title = @"allLine";
                [self.mapView addOverlay:lineOne];
                realCnt = 0;
                pointsToUse[realCnt++] = marsCoords;
                isJam = YES;
            } else if (isJam && i > edJamIdx) {
                BMKPolyline *lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:realCnt];
                TrafficJam * jamPair = jamArr[jamIdx];
                if (jamPair.end_date && jamPair.start_date && [jamPair.end_date timeIntervalSinceDate:jamPair.start_date] > cHeavyTrafficJamThreshold) {
                    lineOne.title = @"heavyJamLine";
                } else {
                    lineOne.title = @"jamLine";
                }
                [self.mapView addOverlay:lineOne];
                realCnt = 0;
                pointsToUse[realCnt++] = marsCoords;
                isJam = NO;
                jamIdx++;
                if (jamIdx < jamLogArr.count) {
                    TSPair * curJamPair = jamLogArr[jamIdx];
                    stJamIdx = [curJamPair.first integerValue];
                    edJamIdx = [curJamPair.second integerValue];
                }
            }
        }
        
        BMKPolyline *lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:realCnt];
        lineOne.title = isJam ? @"jamLine" : @"allLine";
        [self.mapView addOverlay:lineOne];

        
        region.center.latitude     = (maxLat + minLat) / 2 - 0.007;
        region.center.longitude    = (maxLon + minLon) / 2;
        region.span.latitudeDelta  = (maxLat - minLat)/2.0 + 0.018;
        region.span.longitudeDelta = (maxLon - minLon)/2.0 + 0.018;
        [self.mapView setRegion:region animated:YES];
        
        delete [] pointsToUse;
    }
    
    [self.mapView reloadInputViews];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"]) {
        NSValue *oldVal = [change objectForKey:NSKeyValueChangeOldKey];
        NSValue *newVal = [change objectForKey:NSKeyValueChangeNewKey];
        if (nil == newVal || nil == oldVal || [oldVal isEqual:newVal]) {
            return;
        }
        CGRect oldRect = self.overLayerVC.collectionView.frame;
        oldRect.size = [newVal CGSizeValue];
        self.overLayerVC.collectionView.frame = oldRect;
        
        CGSize contentSize = self.rootScrollView.contentSize;
        CGRect scrollFrame = self.rootScrollView.bounds;
        contentSize.height = (scrollFrame.size.height - OVER_HEADER_HEIGHT) + oldRect.size.height;
        self.rootScrollView.contentSize = contentSize;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark -
#pragma mark implement BMKMapViewDelegate

- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay
{
    BMKOverlayView* overlayView = nil;
    if ([overlay isKindOfClass:[BMKPolyline class]])
    {
        BMKPolyline * line = (BMKPolyline*)overlay;
        BMKPolylineView * routeLineView = [[BMKPolylineView alloc] initWithPolyline:line];
        routeLineView.lineWidth = 3;
        if ([line.title isEqualToString:@"allLine"]) {
            routeLineView.strokeColor = [UIColor colorWithRed:69.0f/255.0f green:212.0f/255.0f blue:255.0f/255.0f alpha:0.9];
        } else if ([line.title isEqualToString:@"jamLine"]) {
            routeLineView.strokeColor = [UIColor colorWithRed:168.0f/255.0f green:12.0f/255.0f blue:155.0f/255.0f alpha:0.9];
        } else if ([line.title isEqualToString:@"heavyJamLine"]) {
            routeLineView.strokeColor = [UIColor colorWithRed:255.0f/255.0f green:12.0f/255.0f blue:55.0f/255.0f alpha:0.9];
        }
        
        overlayView = routeLineView;
    }
    return overlayView;
}


- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        return [self getRouteAnnotationView:mapView viewForAnnotation:(RouteAnnotation*)annotation];
    }
    return nil;
}

- (BMKAnnotationView*)getRouteAnnotationView:(BMKMapView *)mapview viewForAnnotation:(RouteAnnotation*)routeAnnotation
{
    BMKAnnotationView* view = nil;
    switch (routeAnnotation.type) {
        case 0:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"start_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"];
                view.image = [self.bdHelper imageNamed:@"images/icon_nav_start.png"];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 1:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"end_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"end_node"];
                view.image = [self.bdHelper imageNamed:@"images/icon_nav_end.png"];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 2:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"route_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"route_node"];
                view.canShowCallout = TRUE;
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [self.bdHelper imageNamed:@"images/icon_direction.png"];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
            
        }
            break;
        case 3:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"waypoint_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"waypoint_node"];
                view.canShowCallout = TRUE;
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [self.bdHelper imageNamed:@"images/icon_nav_waypoint.png"];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
        }
            break;
        default:
            break;
    }
    
    return view;
}

@end
