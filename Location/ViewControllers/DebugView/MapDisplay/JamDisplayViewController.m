//
//  JamDisplayViewController.m
//  TripMan
//
//  Created by taq on 4/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "JamDisplayViewController.h"
#import "BaiduHelper.h"
#import "CTRealtimeJamFacade.h"
#import "RouteAnnotation.h"
#import "UIImage+Rotate.h"
#import "JamZone.h"

@interface JamDisplayViewController ()

@property (nonatomic, strong) BaiduHelper *     bdHelper;

@end

@implementation JamDisplayViewController

- (void)internalInit {
    [super internalInit];
    self.bdHelper = [BaiduHelper new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"实时拥堵地图";
    
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
    
    [self updateUserLocation];
    BMKCoordinateRegion viewRegion = BMKCoordinateRegionMake([BussinessDataProvider lastGoodLocation].coordinate, BMKCoordinateSpanMake(0.5, 0.5));
    BMKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion animated:YES];
    
    [self requestJamWithZone];
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

- (IBAction)refresh:(id)sender {
    [self requestJamWithZone];
}

- (void) requestJamWithZone
{
    GeoRectBound * bound = [GeoRectBound new];
    BMKCoordinateRegion region = self.mapView.region;
    bound.minLat = region.center.latitude - region.span.latitudeDelta;
    bound.maxLat = region.center.latitude + region.span.latitudeDelta;
    bound.minLon = region.center.longitude - region.span.longitudeDelta;
    bound.maxLon = region.center.longitude + region.span.longitudeDelta;
    
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
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    for (JamZone * zone in jamArr) {
        CLLocationCoordinate2D bdCoor = [GeoTransformer earth2Baidu:zone.position.coordinate];
        
        RouteAnnotation* itemNode = [[RouteAnnotation alloc] init];
        itemNode.coordinate = bdCoor;
        itemNode.degree = [zone headingDegree];
        itemNode.type = 2;
        [_mapView addAnnotation:itemNode];
        
        
        BMKCircle * circle = [BMKCircle circleWithCenterCoordinate:bdCoor radius:[zone.radius floatValue]];
        [self.mapView addOverlay:circle];
    }
    
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
