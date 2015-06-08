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
#import "CTTestFacade.h"
#import "RouteAnnotation.h"
#import "UIImage+Rotate.h"
#import "JamZone.h"
#import "RouteOverlayView.h"
#import "ActionSheetStringPicker.h"

typedef NS_ENUM(NSUInteger, eDispMapType) {
    eDispMapTypeJam = 0,
    eDispMapTypeTest,
};

@interface JamDisplayViewController ()

@property (nonatomic, strong) BaiduHelper *     bdHelper;
@property (nonatomic) eDispMapType              dispType;

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
    self.dispType = eDispMapTypeJam;
    
    if (nil == self.mapView) {
        self.mapView = [[BMKMapView alloc] initWithFrame:self.view.bounds];
        self.mapView.delegate = self;
        self.mapView.zoomEnabled = YES;
        self.mapView.scrollEnabled = YES;
        self.mapView.showsUserLocation = YES;
        self.mapView.userTrackingMode = BMKUserTrackingModeNone;
        [self.view addSubview:self.mapView];
    }
    self.mapView.showsUserLocation = YES;
    
    [self updateUserLocation];
    BMKCoordinateRegion viewRegion = BMKCoordinateRegionMake([BussinessDataProvider lastGoodLocation].coordinate, BMKCoordinateSpanMake(0.5, 0.5));
    BMKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion animated:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self requestJamWithZone];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.mapView.frame = self.view.bounds;
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
    [ActionSheetStringPicker showPickerWithTitle:@"选择要显示的内容" rows:@[@"实时拥堵地图", @"路径拆分"] initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        self.title = selectedValue;
        if (0 == selectedIndex) {
            self.dispType = eDispMapTypeJam;
            [self requestJamWithZone];
        } else if (1 == selectedIndex) {
            self.dispType = eDispMapTypeTest;
            [self requestTestDataWithZone];
        }
    } cancelBlock:nil origin:self.view];
}

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

- (void) requestTestDataWithZone
{
    GeoRectBound * bound = [BaiduHelper getBoundingBox:self.mapView.visibleMapRect];

    CTTestFacade * facade = [[CTTestFacade alloc] init];
    facade.geoBound = bound;
    [facade requestWithSuccess:^(NSArray * jamArr) {
        [self updateWithTestArr:jamArr];
    } failure:^(NSError * err) {
        NSLog(@"err = %@", err);
    }];
}

- (void) updateWithTestArr:(NSArray*)jamArr
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    for (CTJam * jam in jamArr) {
        CLLocationCoordinate2D fromCoor = jam.from.coordinate;//[GeoTransformer earth2Baidu:jam.from.coordinate];
        CLLocationCoordinate2D toCoor = jam.to.coordinate;//[GeoTransformer earth2Baidu:jam.to.coordinate];
        
        BMKMapPoint jamsToUse[2];
        jamsToUse[0] = BMKMapPointForCoordinate(fromCoor);
        jamsToUse[1] = BMKMapPointForCoordinate(toCoor);
        
        RouteOverlay * jamOne = [RouteOverlay routeWithPoints:jamsToUse count:2];
        jamOne.title = @"route_arrow";
        [self.mapView addOverlay:jamOne];
        
        BMKCircle * circleSt = [BMKCircle circleWithCenterCoordinate:fromCoor radius:8];
        circleSt.title = @"start";
        [self.mapView addOverlay:circleSt];
        
        BMKCircle * circleEd = [BMKCircle circleWithCenterCoordinate:toCoor radius:10];
        circleEd.title = @"end";
        [self.mapView addOverlay:circleEd];
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
    if ([overlay isKindOfClass:[RouteOverlay class]])
    {
        RouteOverlayView * routeView = [[RouteOverlayView alloc] initWithOverlay:overlay];
        routeView.lineWidth = 10;
        return routeView;
    }
    else if ([overlay isKindOfClass:[BMKCircle class]])
    {
        BMKCircleView * circleRender=[[BMKCircleView alloc] initWithOverlay:overlay];
        BMKCircle * circleOverlay = (BMKCircle*)overlay;
        if ([circleOverlay.title isEqualToString:@"start"]) {
            circleRender.strokeColor = [UIColor redColor];
        } else {
            circleRender.strokeColor = [UIColor greenColor];
        }
        circleRender.lineWidth = 5.0;
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

- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (eDispMapTypeJam == self.dispType) {
            [self requestJamWithZone];
        } else if (eDispMapTypeTest == self.dispType) {
            [self requestTestDataWithZone];
        }
    });
}

@end
