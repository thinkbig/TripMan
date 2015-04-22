//
//  BaiduMapViewController.m
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaiduMapViewController.h"
#import "RouteAnnotation.h"
#import "BaiduHelper.h"
#import "UIImage+Rotate.h"
#import "GPSOffTimeFilter.h"
#import "GeoRectBound.h"
#import "GeoTransformer.h"
#import "TrafficJam+Fetcher.h"
#import "NSDate+Utilities.h"
#import "TrafficJam+Fetcher.h"

@interface BaiduMapViewController ()

@property (nonatomic, strong) BaiduHelper *     bdHelper;
@property (nonatomic, strong) NSArray *         locationArr;

@end

@implementation BaiduMapViewController

- (void)internalInit {
    [super internalInit];
    self.bdHelper = [BaiduHelper new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    if (nil == self.mapView) {
        self.mapView = [[BMKMapView alloc] initWithFrame:self.view.bounds];
        self.mapView.delegate = self;
        self.mapView.zoomEnabled = YES;
        self.mapView.scrollEnabled = YES;
        self.mapView.showsUserLocation = YES;
        self.mapView.userTrackingMode = BMKUserTrackingModeFollow;
        [self.view addSubview:self.mapView];
    }
    self.mapView.showsUserLocation = YES;
    
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:self.tripSum withAnalyzer:nil];
    
    NSString * keyRouteStr = self.tripSum.addi_info;
    self.route = [[CTRoute alloc] initWithString:keyRouteStr error:nil];
    [self updateRouteViewWithRoute:self.route coorType:eCoorTypeGps];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateRouteViewWithRoute:(CTRoute*)route coorType:(eCoorType)coorType
{
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.annotations];
    
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
    itemSt.coordinate = [GeoTransformer baiduCoor:[startLoc coordinate] fromType:coorType];
    itemSt.title = @"起点";
    itemSt.type = 0;
    [_mapView addAnnotation:itemSt];
    [regionBound updateBoundsWithCoor:itemSt.coordinate];
    
    RouteAnnotation* itemEd = [[RouteAnnotation alloc] init];
    itemEd.coordinate = [GeoTransformer baiduCoor:[endLoc coordinate] fromType:coorType];
    itemEd.title = @"终点";
    itemEd.type = 1;
    [_mapView addAnnotation:itemEd];
    [regionBound updateBoundsWithCoor:itemEd.coordinate];
    
    [self.mapView setRegion:[regionBound baiduRegion] animated:YES];
    
    [self.mapView reloadInputViews];
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
        routeLineView.lineWidth = 8;
        if ([line.title isEqualToString:@"green"]) {
            routeLineView.strokeColor = COLOR_STAT_GREEN;
        } else if ([line.title isEqualToString:@"yellow"]) {
            routeLineView.strokeColor = COLOR_STAT_YELLOW;
        } else if ([line.title isEqualToString:@"red"]) {
            routeLineView.strokeColor = COLOR_STAT_RED;
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
