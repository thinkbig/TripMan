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
#import "GRoadSnapFacade.h"

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
    
    // 这一行发布去掉
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:self.tripSum withAnalyzer:nil];
    
    NSString * keyRouteStr = self.tripSum.addi_info;
    self.locationArr = [GPSOffTimeFilter stringToLocationRoute:keyRouteStr];    // gps坐标
    
    [self reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) reloadData
{
    if (self.locationArr.count < 2) {
        return;
    }
    [self updateMapWithRoute:self.locationArr coorType:eCoorTypeGps];
    
    return;
    // snap to road
    GRoadSnapFacade * facade = [[GRoadSnapFacade alloc] init];
    facade.snapPath = self.locationArr; // 输入是gps坐标
    facade.interpolate = YES;
    [facade requestWithSuccess:^(NSArray * snapRoute) {
        [self updateMapWithRoute:snapRoute coorType:eCoorTypeMars];
    } failure:^(NSError * err) {
        NSLog(@"GRoadSnapFacade err = %@", err);
    }];
}

- (void) updateMapWithRoute:(NSArray*)route coorType:(eCoorType)coorType
{
    if (route.count < 2) {
        return;
    }
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    GeoRectBound * regionBound = [GeoRectBound new];

    BMKMapPoint pointsToUse[route.count];
    for (int i = 0; i < route.count; i++) {
        id item = route[i];
        CLLocationCoordinate2D itemCoor = [item coordinate];
        if (eCoorTypeGps == coorType) {
            itemCoor = [GeoTransformer earth2Baidu:itemCoor];
        } else if (eCoorTypeMars == coorType) {
            itemCoor = [GeoTransformer mars2Baidu:itemCoor];
        }
        BMKMapPoint bdCoor = BMKMapPointForCoordinate(itemCoor);
        pointsToUse[i] = bdCoor;
        [regionBound updateBoundsWithCoor:itemCoor];
        
        if (i == 0) {
            RouteAnnotation* itemSt = [[RouteAnnotation alloc] init];
            itemSt.coordinate = itemCoor;
            itemSt.title = @"起点";
            itemSt.type = 0;
            [_mapView addAnnotation:itemSt];
        } else if (route.count-1 == i) {
            RouteAnnotation* itemEd = [[RouteAnnotation alloc] init];
            itemEd.coordinate = itemCoor;
            itemEd.title = @"终点";
            itemEd.type = 1;
            [_mapView addAnnotation:itemEd];
        }
    }

    BMKPolyline * lineOne = [BMKPolyline polylineWithPoints:pointsToUse count:route.count];
    lineOne.title = @"green";
    [self.mapView addOverlay:lineOne];
    
    [self.mapView setRegion:[regionBound baiduRegion] animated:YES];
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
