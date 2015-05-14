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
#import "RouteOverlayView.h"
#import "BCarAnnotationView.h"
#import "CTRealtimeJamFacade.h"

#define OVER_HEADER_HEIGHT      114

@interface SuggestDetailViewController ()

@property (nonatomic, strong) SuggestOverLayerCollectionViewController *    overLayerVC;
@property (nonatomic, strong) NSArray *         gpsLogs;
@property (nonatomic, strong) NSArray *         jamIndex;
@property (nonatomic) CGPoint                   lastTouchLoc;
@property (nonatomic) BOOL                      isOpen;
@property (nonatomic, strong) BaiduHelper *     bdHelper;

@property (nonatomic, strong) NSMutableArray *         routeAnnos;
@property (nonatomic, strong) NSMutableArray *         carAnnos;

@end

@implementation SuggestDetailViewController

- (void)internalInit
{
    [super internalInit];

    self.routeAnnos = [NSMutableArray array];
    self.carAnnos = [NSMutableArray array];
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

    self.rootScrollView.scrollEnabled = NO;
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
            if (offset.y > thresOffset) {
                self.rootScrollView.scrollEnabled = YES;
            } else {
                self.rootScrollView.scrollEnabled = NO;
            }
        }
    }
}

//- (void) requestRouteFromApple
//{
//    CLLocationCoordinate2D sourceCoords = [GeoTransformer baidu2Mars:[self.route.orig clLocation].coordinate];
//    MKPlacemark *sourcePlacemark = [[MKPlacemark alloc] initWithCoordinate:sourceCoords addressDictionary:nil];
//    MKMapItem *source = [[MKMapItem alloc] initWithPlacemark:sourcePlacemark];
//    
//    CLLocationCoordinate2D destinationCoords = [GeoTransformer baidu2Mars:[self.route.dest clLocation].coordinate];
//    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:destinationCoords addressDictionary:nil];
//    MKMapItem *destination = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];
//    
//    MKDirectionsRequest *directionsRequest = [MKDirectionsRequest new];
//    [directionsRequest setSource:source];
//    [directionsRequest setDestination:destination];
//    
//    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
//    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
//        // Handle the response here
//        [self.mapView removeOverlays:self.mapView.overlays];
//        
//        for (MKRoute * route in response.routes)
//        {
//            NSUInteger ptCnt = route.polyline.pointCount;
//            CLLocationCoordinate2D routeCoordinates[ptCnt];
//            [route.polyline getCoordinates:routeCoordinates range:NSMakeRange(0, ptCnt)];
//            
//            BMKMapPoint pointsToUse[ptCnt];
//            for (int i=0; i < ptCnt; i++) {
//                CLLocationCoordinate2D coor = routeCoordinates[i];
//                CLLocationCoordinate2D bdCoor = [GeoTransformer mars2Baidu:coor];
//                BMKMapPoint bdMapPt = BMKMapPointForCoordinate(bdCoor);
//                pointsToUse[i] = bdMapPt;
//            }
//            
//            BMKPolyline * lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:ptCnt];
//            lineOne.title = @"green";
//            [self.mapView addOverlay:lineOne];
//        }
//        
//        [self.mapView reloadInputViews];
//    }];
//}

- (void) requestJamWithZone
{
    GeoRectBound * bound = [BaiduHelper getBoundingBox:self.mapView.visibleMapRect];
    
    CTRealtimeJamFacade * facade = [[CTRealtimeJamFacade alloc] init];
    facade.geoBound = bound;
    [facade requestWithSuccess:^(NSArray * jamArr) {
        [self updateWithJamArr:jamArr];
    } failure:^(NSError * err) {
        NSLog(@"err = %@", err);
    }];
}

- (void) updateWithJamArr:(NSArray*)jamArr
{
    [self.mapView removeAnnotations:self.carAnnos];
    [self.carAnnos removeAllObjects];
    
    NSInteger idx = 1;
    for (JamZone * zone in jamArr) {
        CLLocationCoordinate2D bdCoor = [GeoTransformer earth2Baidu:zone.position.coordinate];

        RouteAnnotation* carAnnotation = [[RouteAnnotation alloc] init];
        carAnnotation.coordinate = bdCoor;
        carAnnotation.degree = [zone headingDegree];
        carAnnotation.type = 4;
        carAnnotation.title = [NSString stringWithFormat:@"%ld", idx++];
        [self.carAnnos addObject:carAnnotation];
    }
    
    for (RouteAnnotation * anno in self.carAnnos) {
        [_mapView addAnnotation:anno];
    }
    
    [self.mapView reloadInputViews];
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
}

- (void) updateRouteViewWithRoute:(CTRoute*)route
{
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.routeAnnos];
    [self.routeAnnos removeAllObjects];
    
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
        [self.routeAnnos addObject:itemNode];
        
        [pathArr enumerateObjectsUsingBlock:^(CTBaseLocation * obj, NSUInteger idx, BOOL *stop) {
            CLLocationCoordinate2D btCoor = [GeoTransformer baiduCoor:[obj coordinate] fromType:coorType];
            [regionBound updateBoundsWithCoor:btCoor];
            BMKMapPoint bdMappt = BMKMapPointForCoordinate(btCoor);
            pointsToUse[idx+1] = bdMappt;
        }];
        
        RouteOverlay * lineOne = [RouteOverlay routeWithPoints:pointsToUse count:pathArr.count+2];
        lineOne.title = @"green";
        [self.mapView addOverlay:lineOne];
        
        delete [] pointsToUse;
        
        // 处理堵车数据
        NSArray * filteredJamArr = [oneStep jamsWithThreshold:cTrafficJamThreshold];
        CLLocation * origLoc = [route.orig clLocation];
        CLLocation * destLoc = [route.dest clLocation];
        for (CTJam * jam in filteredJamArr) {
            [jam calCoefWithStartLoc:origLoc andEndLoc:destLoc];
            NSArray * jamArr = [oneStep fullPathOfJam:jam];
            if (jamArr.count > 0) {
                BMKMapPoint * jamsToUse = new BMKMapPoint[jamArr.count];
                [jamArr enumerateObjectsUsingBlock:^(CTBaseLocation * obj, NSUInteger idx, BOOL *stop) {
                    CLLocationCoordinate2D btCoor = [GeoTransformer baiduCoor:[obj coordinate] fromType:coorType];
                    BMKMapPoint bdMappt = BMKMapPointForCoordinate(btCoor);
                    jamsToUse[idx] = bdMappt;
                }];
                
                eStepTraffic stat = [jam trafficStat];
                RouteOverlay * jamOne = [RouteOverlay routeWithPoints:jamsToUse count:jamArr.count];
                if (eStepTrafficVerySlow == stat) {
                    jamOne.title = @"red";
                } else if (eStepTrafficSlow == stat) {
                    jamOne.title = @"yellow";
                } else {
                    jamOne.title = @"green";
                }
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
    [self.routeAnnos addObject:itemSt];
    [regionBound updateBoundsWithCoor:itemSt.coordinate];
    
    RouteAnnotation* itemEd = [[RouteAnnotation alloc] init];
    itemEd.coordinate = [endLoc coordinate];
    itemEd.title = @"终点";
    itemEd.type = 1;
    [self.routeAnnos addObject:itemEd];
    [regionBound updateBoundsWithCoor:itemEd.coordinate];
    
    for (RouteAnnotation * anno in self.routeAnnos) {
        [_mapView addAnnotation:anno];
    }
    
    [self.mapView setRegion:[regionBound baiduRegion] animated:YES];
    
    [self.mapView reloadInputViews];
    
    [self requestJamWithZone];
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
    
    if (offset.y > thresOffset) {
        self.rootScrollView.scrollEnabled = YES;
    } else {
        self.rootScrollView.scrollEnabled = NO;
    }
}


#pragma mark -
#pragma mark implement BMKMapViewDelegate

- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay
{
    BMKOverlayView* overlayView = nil;
    if ([overlay isKindOfClass:[RouteOverlay class]])
    {
        RouteOverlayView * routeView = [[RouteOverlayView alloc] initWithOverlay:overlay];
        routeView.lineWidth = 10;
        return routeView;
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
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [self.bdHelper imageNamed:@"images/icon_nav_waypoint.png"];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
        }
            break;
        case 4:
        {
            BCarAnnotationView * realView = (BCarAnnotationView*)[mapview dequeueReusableAnnotationViewWithIdentifier:@"car_node"];
            if (realView == nil) {
                realView = [[BCarAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"car_node"];
                realView.canShowCallout = TRUE;
            } else {
                [realView setNeedsDisplay];
            }
            
            [realView updateWithIcon:@"map_car_male.png" andText:routeAnnotation.title withAngle:routeAnnotation.degree-90];
            realView.clipsToBounds = NO;
            
            view = realView;
        }
            break;
        default:
            break;
    }
    
    return view;
}

- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self requestJamWithZone];
    });
}

@end
