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
#import "CTTrafficFullFacade.h"
#import "GeoRectBound.h"
#import "RouteAnnotation.h"
#import "CTTimePredictFacade.h"

#define OVER_HEADER_HEIGHT      114

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation) name:kNotifyGoodLocationUpdated object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.overLayerVC.collectionView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.rootScrollView.delegate = self;
    CGRect scrollFrame = self.rootScrollView.bounds;
    // add header and content
    if (nil == self.mapView) {
        CGRect mapRc = scrollFrame;
        mapRc.size.height -= OVER_HEADER_HEIGHT-25;
        self.mapView = [[BMKMapView alloc] initWithFrame:mapRc];
        self.mapView.delegate = self;
        self.mapView.zoomEnabled = YES;
        self.mapView.scrollEnabled = YES;
        [self.rootScrollView addSubview:self.mapView withAcceleration:CGPointMake(0.0, 0.5)];
    }
    self.mapView.userTrackingMode = BMKUserTrackingModeNone;
    self.mapView.showsUserLocation = YES;
    
    [self updateUserLocation];
    BMKCoordinateRegion viewRegion = BMKCoordinateRegionMake([BussinessDataProvider lastGoodLocation].coordinate, BMKCoordinateSpanMake(0.5, 0.5));
    BMKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion animated:YES];
    
    if (nil == self.overLayerVC) {
        self.overLayerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestOverLay"];
        self.overLayerVC.view.frame = scrollFrame;
        self.overLayerVC.collectionView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main_bg"]];
        [self.rootScrollView addSubview:self.overLayerVC.view];
    }
    
    [self.overLayerVC.collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOverLayer:)];
    [self.overLayerVC.collectionView addGestureRecognizer:panGesture];
    
    [self showLoading];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    CGRect scrollFrame = self.rootScrollView.bounds;
    CGRect mapRc = scrollFrame;
    
    scrollFrame.origin.y = (scrollFrame.size.height - OVER_HEADER_HEIGHT);
    self.overLayerVC.view.frame = scrollFrame;
    
    CGSize contentSize = self.rootScrollView.frame.size;
    contentSize.height = CGRectGetMaxY(scrollFrame);
    self.rootScrollView.contentSize = contentSize;
    
    mapRc.size.height -= OVER_HEADER_HEIGHT-25;
    self.mapView.frame = mapRc;
    
    CGPoint offset = self.rootScrollView.contentOffset;
    offset.y = self.rootScrollView.height - OVER_HEADER_HEIGHT;
    [self.rootScrollView setContentOffset:offset animated:NO];
    
    [self updateTripInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateUserLocation
{
    CLLocation * userLoc = [BussinessDataProvider lastGoodLocation];
    if (userLoc) {
        CLLocationCoordinate2D bdCoor = [GeoTransformer earth2Baidu:userLoc.coordinate];
        BMKUserLocation * userLoc = [[BMKUserLocation alloc] init];
        [userLoc setValue:[[CLLocation alloc] initWithLatitude:bdCoor.latitude longitude:bdCoor.longitude] forKey:@"location"];
        [self.mapView updateLocationData:userLoc];
    }
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

- (void) requestRouteFromApple
{
    CLLocationCoordinate2D sourceCoords = [GeoTransformer baidu2Mars:[self.route.orig clLocation].coordinate];
    MKPlacemark *sourcePlacemark = [[MKPlacemark alloc] initWithCoordinate:sourceCoords addressDictionary:nil];
    MKMapItem *source = [[MKMapItem alloc] initWithPlacemark:sourcePlacemark];
    
    CLLocationCoordinate2D destinationCoords = [GeoTransformer baidu2Mars:[self.route.dest clLocation].coordinate];
    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:destinationCoords addressDictionary:nil];
    MKMapItem *destination = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];
    
    MKDirectionsRequest *directionsRequest = [MKDirectionsRequest new];
    [directionsRequest setSource:source];
    [directionsRequest setDestination:destination];
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        // Handle the response here
        [self.mapView removeOverlays:self.mapView.overlays];
        
        for (MKRoute * route in response.routes)
        {
            NSUInteger ptCnt = route.polyline.pointCount;
            CLLocationCoordinate2D routeCoordinates[ptCnt];
            [route.polyline getCoordinates:routeCoordinates range:NSMakeRange(0, ptCnt)];
            
            BMKMapPoint pointsToUse[ptCnt];
            for (int i=0; i < ptCnt; i++) {
                CLLocationCoordinate2D coor = routeCoordinates[i];
                CLLocationCoordinate2D bdCoor = [GeoTransformer mars2Baidu:coor];
                BMKMapPoint bdMapPt = BMKMapPointForCoordinate(bdCoor);
                pointsToUse[i] = bdMapPt;
            }
            
            BMKPolyline * lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:ptCnt];
            lineOne.title = @"green";
            [self.mapView addOverlay:lineOne];
        }
        
        [self.mapView reloadInputViews];
    }];
}

- (void)updateTripInfo
{
    if (self.route.orig && self.route.dest)
    {
        if (self.route.steps.count == 0) {
            CLLocation * mLoc = [BussinessDataProvider lastGoodLocation];
            ParkingRegionDetail * startDetail = [[AnaDbManager deviceDb] parkingDetailForCoordinate:mLoc.coordinate minDist:500];
            
            [self showLoading];
            CTTrafficFullFacade * facade = [[CTTrafficFullFacade alloc] init];
            facade.fromCoorBaidu = [self.route.orig clLocation].coordinate;
            facade.toCoorBaidu = [self.route.dest clLocation].coordinate;
            if (startDetail && self.endParkingId) {
                facade.fromParkingId = startDetail.coreDataItem.parking_id;
                facade.toParkingId = self.endParkingId;
            }
            [facade requestWithSuccess:^(CTRoute * result) {
                [self hideLoading];
                self.mapView.userTrackingMode = BMKUserTrackingModeNone;
                [self.route mergeFromAnother:result];
                [self updateRouteViewWithRoute:self.route];
                self.overLayerVC.route = self.route;
                [self.overLayerVC.collectionView reloadData];
                
                CTTimePredictFacade * predFacade = [[CTTimePredictFacade alloc] init];
                predFacade.fromCoorBaidu = [self.route.orig clLocation].coordinate;
                predFacade.toCoorBaidu = [self.route.dest clLocation].coordinate;
                if (startDetail && self.endParkingId) {
                    predFacade.fromParkingId = startDetail.coreDataItem.parking_id;
                    predFacade.toParkingId = self.endParkingId;
                }
                [predFacade requestWithSuccess:^(NSDictionary * predict) {
                    self.overLayerVC.predictDict = predict;
                    [self.overLayerVC.collectionView reloadData];
                } failure:^(NSError * err) {
                    [self showToast:@"暂时无法获得交通预测数据" onDismiss:nil];
                }];
                
                [UIView animateWithDuration:1.0 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    [self.rootScrollView setContentOffset:CGPointMake(0, 0) animated:NO];
                } completion:nil];
                
            } failure:^(NSError * err) {
                [self hideLoading];
                [self showToast:@"暂时无法获得交通数据" onDismiss:^(id toast) {
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            }];
            
        } else {
            [self updateRouteViewWithRoute:self.route];
            self.overLayerVC.route = self.route;
            [self.overLayerVC.collectionView reloadData];
        }
    }
    else if (self.tripSum)
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
        
        [self updateRouteView:[GPSOffTimeFilter smoothGPSData:_gpsLogs iteratorCnt:3]];
        
        [UIView animateWithDuration:1.0 delay:0.6 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.rootScrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        } completion:nil];
    }
}

- (void) updateRouteViewWithRoute:(CTRoute*)route
{
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    eCoorType coorType = [route coorType];
    NSArray * steps = route.steps;
    GeoRectBound * regionBound = [GeoRectBound new];
    
    for (CTStep * oneStep in steps)
    {
        CLLocationCoordinate2D bdCoorFrom = [GeoTransformer baiduCoor:[oneStep.from coordinate] fromType:coorType];
        BMKMapPoint bdMapFrom = BMKMapPointForCoordinate(bdCoorFrom);
        [regionBound updateBoundsWithCoor:bdCoorFrom];
        
        CLLocationCoordinate2D btCoorTo = [GeoTransformer baiduCoor:[oneStep.to coordinate] fromType:coorType];
        BMKMapPoint bdMapTo = BMKMapPointForCoordinate(btCoorTo);
        [regionBound updateBoundsWithCoor:btCoorTo];
        
        NSArray * pathArr = [oneStep pathArray];
        
        BMKMapPoint * pointsToUse = new BMKMapPoint[pathArr.count+2];
        pointsToUse[0] = bdMapFrom;
        pointsToUse[pathArr.count+1] = bdMapTo;
        
        // 转弯节点添加标注
        RouteAnnotation* itemNode = [[RouteAnnotation alloc] init];
        itemNode.coordinate = bdCoorFrom;
        itemNode.degree = [BaiduHelper mapAngleFromPoint:CGPointMake(bdCoorFrom.longitude, bdCoorFrom.latitude) toPoint:CGPointMake(btCoorTo.longitude, btCoorTo.latitude)];
        itemNode.type = 2;
        [_mapView addAnnotation:itemNode];
        
        [pathArr enumerateObjectsUsingBlock:^(CTBaseLocation * obj, NSUInteger idx, BOOL *stop) {
            CLLocationCoordinate2D btCoor = [GeoTransformer baiduCoor:[obj coordinate] fromType:coorType];
            [regionBound updateBoundsWithCoor:btCoor];
            BMKMapPoint bdMappt = BMKMapPointForCoordinate(btCoor);
            pointsToUse[idx+1] = bdMappt;
        }];
        
        BMKPolyline * lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:pathArr.count+2];
        lineOne.title = @"green";
        [self.mapView addOverlay:lineOne];
        
        delete [] pointsToUse;
        
        // 处理堵车数据
        NSArray * filteredJamArr = [oneStep jamsWithThreshold:cTrafficJamThreshold];
        for (CTJam * jam in filteredJamArr) {
            NSArray * jamArr = [oneStep fullPathOfJam:jam];
            if (jamArr.count > 0) {
                BMKMapPoint * jamsToUse = new BMKMapPoint[jamArr.count];
                [jamArr enumerateObjectsUsingBlock:^(CTBaseLocation * obj, NSUInteger idx, BOOL *stop) {
                    CLLocationCoordinate2D btCoor = [GeoTransformer baiduCoor:[obj coordinate] fromType:coorType];
                    BMKMapPoint bdMappt = BMKMapPointForCoordinate(btCoor);
                    jamsToUse[idx] = bdMappt;
                }];
                
                eStepTraffic stat = [jam trafficStat];
                BMKPolyline * jamOne = [BMKPolyline polylineWithPoints:jamsToUse count:jamArr.count];
                jamOne.title = (eStepTrafficVerySlow == stat) ? @"red" : @"yellow";
                [self.mapView addOverlay:jamOne];
                
                delete [] jamsToUse;
            }
        }
    }
    
    CTBaseLocation * startLoc = route.orig;
    CTBaseLocation * endLoc = route.dest;
    
    RouteAnnotation* itemSt = [[RouteAnnotation alloc] init];
    itemSt.coordinate = [startLoc coordinate];
    itemSt.title = @"起点";
    itemSt.type = 0;
    [_mapView addAnnotation:itemSt];
    [regionBound updateBoundsWithCoor:itemSt.coordinate];
    
    RouteAnnotation* itemEd = [[RouteAnnotation alloc] init];
    itemEd.coordinate = [endLoc coordinate];
    itemEd.title = @"终点";
    itemEd.type = 1;
    [_mapView addAnnotation:itemEd];
    [regionBound updateBoundsWithCoor:itemEd.coordinate];
    
    [self.mapView setRegion:[regionBound baiduRegion] animated:YES];
    
    [self.mapView reloadInputViews];
}

- (void) updateRouteViewWithRoute1:(CTRoute*)route
{
    [self.mapView removeOverlays:self.mapView.overlays];
    
    NSArray * steps = route.steps;
    eCoorType coorType = [route coorType];
    GeoRectBound * regionBound = [GeoRectBound new];
    
    for (CTStep * oneStep in steps)
    {
        CLLocationCoordinate2D bdCoorFrom = [GeoTransformer baiduCoor:[oneStep.from coordinate] fromType:coorType];
        BMKMapPoint bdMapFrom = BMKMapPointForCoordinate(bdCoorFrom);
        [regionBound updateBoundsWithCoor:bdCoorFrom];
        
        CLLocationCoordinate2D btCoorTo = [GeoTransformer baiduCoor:[oneStep.to coordinate] fromType:coorType];
        BMKMapPoint bdMapTo = BMKMapPointForCoordinate(btCoorTo);
        [regionBound updateBoundsWithCoor:btCoorTo];
        
        NSArray * pathArr = [oneStep pathArray];
        
        BMKMapPoint * pointsToUse = new BMKMapPoint[pathArr.count+2];
        pointsToUse[0] = bdMapFrom;
        pointsToUse[pathArr.count+1] = bdMapTo;
        eStepTraffic stat = [oneStep trafficStat];
        
        [pathArr enumerateObjectsUsingBlock:^(CTBaseLocation * obj, NSUInteger idx, BOOL *stop) {
            CLLocationCoordinate2D btCoor = [GeoTransformer baiduCoor:[obj coordinate] fromType:coorType];
            [regionBound updateBoundsWithCoor:btCoor];
            BMKMapPoint bdMappt = BMKMapPointForCoordinate(btCoor);
            pointsToUse[idx+1] = bdMappt;
        }];
        
        BMKPolyline * lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:pathArr.count+2];
        [self.mapView addOverlay:lineOne];
        
        if (eStepTrafficSlow == stat) {
            lineOne.title = @"yellow";
        } else if (eStepTrafficVerySlow == stat) {
            lineOne.title = @"red";
        } else {
            lineOne.title = @"green";
        }

        delete [] pointsToUse;
    }
    
    CTBaseLocation * startLoc = route.orig;
    CTBaseLocation * endLoc = route.dest;

    RouteAnnotation* itemSt = [[RouteAnnotation alloc] init];
    itemSt.coordinate = [startLoc clLocation].coordinate;
    itemSt.title = @"起点";
    itemSt.type = 0;
    [_mapView addAnnotation:itemSt];
    [regionBound updateBoundsWithCoor:itemSt.coordinate];
    
    RouteAnnotation* itemEd = [[RouteAnnotation alloc] init];
    itemEd.coordinate = [endLoc clLocation].coordinate;
    itemEd.title = @"终点";
    itemEd.type = 1;
    [_mapView addAnnotation:itemEd];
    [regionBound updateBoundsWithCoor:itemEd.coordinate];

    [self.mapView setRegion:[regionBound baiduRegion] animated:YES];
    
    [self.mapView reloadInputViews];
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
                lineOne.title = @"green";
                [self.mapView addOverlay:lineOne];
                realCnt = 0;
                pointsToUse[realCnt++] = marsCoords;
                isJam = YES;
            } else if (isJam && i > edJamIdx) {
                BMKPolyline *lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:realCnt];
                TrafficJam * jamPair = jamArr[jamIdx];
                if (jamPair.end_date && jamPair.start_date && [jamPair.end_date timeIntervalSinceDate:jamPair.start_date] > cHeavyTrafficJamThreshold) {
                    lineOne.title = @"red";
                } else {
                    lineOne.title = @"yellow";
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
        lineOne.title = isJam ? @"yellow" : @"green";
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


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGPoint offset = self.rootScrollView.contentOffset;
    self.rootScrollView.contentOffset = offset;
    
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


#pragma mark -
#pragma mark implement BMKMapViewDelegate

- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay
{
    BMKOverlayView* overlayView = nil;
    if ([overlay isKindOfClass:[BMKPolyline class]])
    {
        BMKPolyline * line = (BMKPolyline*)overlay;
        BMKPolylineView * routeLineView = [[BMKPolylineView alloc] initWithPolyline:line];
        routeLineView.lineWidth = 8;
        if ([line.title isEqualToString:@"green"]) {
            routeLineView.strokeColor = [UIColor colorWithRed:20.0f/255.0f green:220.0f/255.0f blue:255.0f/255.0f alpha:0.8];
        } else if ([line.title isEqualToString:@"yellow"]) {
            routeLineView.strokeColor = [UIColor colorWithRed:210.0f/255.0f green:225.0f/255.0f blue:15.0f/255.0f alpha:0.8];
        } else if ([line.title isEqualToString:@"red"]) {
            routeLineView.strokeColor = [UIColor colorWithRed:255.0f/255.0f green:12.0f/255.0f blue:55.0f/255.0f alpha:0.8];
        }
        
        overlayView = routeLineView;
    }
    else if ([overlay isKindOfClass:[BMKCircle class]])
    {
        BMKCircleView * circleRender=[[BMKCircleView alloc] initWithOverlay:overlay] ;
        circleRender.strokeColor=[UIColor colorWithRed:255.0f/255.0f green:112.0f/255.0f blue:155.0f/255.0f alpha:0.9];
        circleRender.lineWidth = 3.0;
        return circleRender;
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
