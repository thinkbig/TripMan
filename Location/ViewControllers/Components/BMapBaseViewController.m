//
//  BMapBaseViewController.m
//  TripMan
//
//  Created by taq on 6/12/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BMapBaseViewController.h"
#import "BaiduHelper.h"
#import "RouteOverlayView.h"
#import "UIImage+Rotate.h"
#import "UIImage+RZResize.h"

@interface BMapBaseViewController () {
    
    CLLocationDegrees _zoomLevel;
}

@end

@implementation BMapBaseViewController

- (void)internalInit {
    [super internalInit];
    self.bdHelper = [BaiduHelper new];
    self.fullTurningAnno = [NSMutableArray array];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSArray*) filterRouteTurning:(NSArray *)turnsToFilter ofSize:(CGSize)annoSz
{
    CGSize size = self.mapView.bounds.size;
    float iphoneScaleFactorLatitude = size.width/annoSz.width;
    float iphoneScaleFactorLongitude = size.height/annoSz.height;
    float latDelta = self.mapView.region.span.latitudeDelta/iphoneScaleFactorLatitude;
    float longDelta = self.mapView.region.span.longitudeDelta/iphoneScaleFactorLongitude;
    
    NSMutableArray * pointToShow = [[NSMutableArray alloc] initWithCapacity:0];
    
    [turnsToFilter enumerateObjectsUsingBlock:^(RouteAnnotation * anno, NSUInteger idx, BOOL *stop) {
        CLLocationDegrees latitude = anno.coordinate.latitude;
        CLLocationDegrees longitude = anno.coordinate.longitude;
        
        bool found=FALSE;
        for (RouteAnnotation * tempPlacemark in pointToShow) {
            if(fabs(tempPlacemark.coordinate.latitude-latitude) < latDelta &&
               fabs(tempPlacemark.coordinate.longitude-longitude) <longDelta ){
                found=TRUE;
                break;
            }
        }
        if (!found) {
            [pointToShow addObject:anno];
        } else if (idx == turnsToFilter.count-1) {
            [pointToShow removeLastObject];
            [pointToShow addObject:anno];
        }
    }];

    return pointToShow;
}


#pragma mark -
#pragma mark implement BMKMapViewDelegate

- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay
{
    BMKOverlayView* overlayView = nil;
    if ([overlay isKindOfClass:[RouteOverlay class]])
    {
        RouteOverlay * routeOverlay = (RouteOverlay*)overlay;
        RouteOverlayView * routeView = [[RouteOverlayView alloc] initWithOverlay:routeOverlay];
        routeView.lineWidth = 10;
        routeView.lineDash = [routeOverlay.subtitle isEqualToString:@"dash"] ? YES : NO;
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
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"];
                view.image = [self.bdHelper imageNamed:@"images/icon_nav_start.png"];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
                view.layer.zPosition = -100;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 1:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"end_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"end_node"];
                view.image = [self.bdHelper imageNamed:@"images/icon_nav_end.png"];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
                view.layer.zPosition = -100;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 2:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"route_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"route_node"];
                view.canShowCallout = TRUE;
                view.layer.zPosition = -200;
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [UIImage imageNamed:@"map_dir_point"];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
            
        }
            break;
        case 3:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"waypoint_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"waypoint_node"];
                view.canShowCallout = TRUE;
                view.layer.zPosition = -200;
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
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"route_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier:@"car_node"];
                view.layer.zPosition = -150;
            } else {
                [view setNeedsDisplay];
            }
            UIImage* image = nil;
            if (routeAnnotation.subType == 101) {
                image = [UIImage imageNamed:@"map_car_male_upset.png"];
            } else if (routeAnnotation.subType == 102) {
                image = [UIImage imageNamed:@"map_car_male_cry.png"];
            } else {
                image = [UIImage imageNamed:@"map_car_male.png"];
            }
            CGSize oldSz = image.size;
            CGSize newSz = CGSizeMake(oldSz.width*0.75, oldSz.height*0.75);
            view.image = [UIImage rz_imageWithImage:image scaledToSize:newSz preserveAspectRatio:YES];
            view.centerOffset = CGPointMake(-3, -newSz.height/2.0+4);
            view.annotation = routeAnnotation;
        }
            break;
        default:
            break;
    }
    
    return view;
}

//- (void)mapView:(BMKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
//    for (MKAnnotationView * annView in views) {
//        RouteAnnotation * ann = (RouteAnnotation *) [annView annotation];
//        if (2 == ann.type) {
//            [[annView superview] sendSubviewToBack:annView];
//        }
//    }
//}

- (void) mapViewDidFinishLoading:(BMKMapView *)mapView {
    [mapView removeAnnotations:self.fullTurningAnno];
    NSArray * filterAnno = [self filterRouteTurning:self.fullTurningAnno ofSize:CGSizeMake(12, 12)];
    [self.mapView addAnnotations:filterAnno];
    _zoomLevel = mapView.region.span.longitudeDelta;
}

- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (_zoomLevel != mapView.region.span.longitudeDelta) {
        [mapView removeAnnotations:self.fullTurningAnno];
        NSArray * filterAnno = [self filterRouteTurning:self.fullTurningAnno ofSize:CGSizeMake(12, 12)];
        [mapView addAnnotations:filterAnno];
        _zoomLevel = mapView.region.span.longitudeDelta;
    }
}

@end
