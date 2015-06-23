//
//  MapDisplayViewController.m
//  Location
//
//  Created by taq on 9/23/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "MapDisplayViewController.h"
#import "GPSLogItem.h"
#import "GeoTransformer.h"
#import "GPSOffTimeFilter.h"
#import "TurningInfo+Fetcher.h"
#import "GRoadSnapFacade.h"
#import "CTTrafficFullFacade.h"
#import "CTRoute.h"
#import "GeoRectBound.h"

@interface MapDisplayViewController ()

@property (nonatomic, strong) NSArray *         gpsLogs;
@property (nonatomic, strong) NSArray *         monitorRegions;

@end

@implementation MapDisplayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:self.tripSum withAnalyzer:nil];
    
    [self updateTripInfo];

    NSArray * rawRoute = [GPSOffTimeFilter keyRouteFromGPS:_gpsLogs autoFilter:YES];
    [self updateRouteView:rawRoute];
    [self updateSnapData:rawRoute];
    
}

- (void) updateWayPointData:(NSArray*)snapData
{
    GSnapPtModel * first = snapData[0];
    GSnapPtModel * last = [snapData lastObject];
    NSMutableArray * bdArr = [NSMutableArray array];
    for (int i = 1; i < snapData.count-1; i++) {
        GSnapPtModel * cur = snapData[i];
        CLLocationCoordinate2D bdCoor = [GeoTransformer mars2Baidu:[cur.location coordinate]];
        [bdArr addObject:@{@"lat": @(bdCoor.latitude), @"lon": @(bdCoor.longitude)}];
    }
    
    CTTrafficFullFacade * facade = [[CTTrafficFullFacade alloc] init];
    facade.fromCoorBaidu = [GeoTransformer mars2Baidu:[first.location coordinate]];
    facade.toCoorBaidu = [GeoTransformer mars2Baidu:[last.location coordinate]];
    [facade requestWithSuccess:^(CTRoute * route) {
        NSLog(@"updateWayPointData");
        [self updateWithBaiduRoute:route];
    } failure:^(NSError * err) {
        NSLog(@"CTTrafficFullFacade err = %@", err);
    }];
}

- (void) updateWithBaiduRoute:(CTRoute*)route
{
    [self.mapView removeOverlays:self.mapView.overlays];
    
    NSArray * steps = route.steps;
    CTBaseLocation * startLoc = route.orig;
    CTBaseLocation * endLoc = route.dest;
    
    GeoRectBound * regionBound = [GeoRectBound new];
    
    MKCircle * circle = [MKCircle circleWithCenterCoordinate:[GeoTransformer baidu2Mars:[startLoc coordinate]] radius:15];
    circle.title = @"ErrCircle";
    [self.mapView addOverlay:circle];
    
    MKCircle * circle1 = [MKCircle circleWithCenterCoordinate:[GeoTransformer baidu2Mars:[endLoc coordinate]] radius:15];
    circle.title = @"ErrCircle";
    [self.mapView addOverlay:circle1];
    
    for (CTStep * oneStep in steps)
    {
        CLLocationCoordinate2D coorFrom = [GeoTransformer baidu2Mars:[oneStep.from coordinate]];
        [regionBound updateBoundsWithCoor:coorFrom];
        
        CLLocationCoordinate2D coorTo = [GeoTransformer baidu2Mars:[oneStep.to coordinate]];
        [regionBound updateBoundsWithCoor:coorTo];
        
        NSArray * pathArr = [oneStep pathArray];
        
        CLLocationCoordinate2D pointsToUse[pathArr.count+2];
        pointsToUse[0] = coorFrom;
        pointsToUse[pathArr.count+1] = coorTo;
        
        for (int i = 0; i < pathArr.count; i++) {
            CTBaseLocation * obj = pathArr[i];
            CLLocationCoordinate2D coor = [GeoTransformer baidu2Mars:[obj coordinate]];
            pointsToUse[i+1] = coor;
        }
        
        MKPolyline * lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:pathArr.count+2];
        lineOne.title = @"allLine";
        [self.mapView addOverlay:lineOne];
    }
    
    [self.mapView setRegion:[regionBound mapRegion] animated:YES];
}

- (void) updateSnapData:(NSArray*)rawRoute
{
//    NSMutableArray * snapRoute = [NSMutableArray arrayWithCapacity:rawRoute.count];
//    for (GPSLogItem * item in rawRoute) {
//        CLLocationCoordinate2D coor = [item locationCoordinate];
//        CLLocationCoordinate2D marsCoor = [GeoTransformer earth2Mars:coor];
//        GSnapPtModel * model = [[GSnapPtModel alloc] init];
//        model.location = [GLocModel new];
//        model.location.latitude = @(marsCoor.latitude);
//        model.location.longitude = @(marsCoor.longitude);
//        [snapRoute addObject:model];
//    }
//    [self updateWayPointData:snapRoute];
//    // google服务被杀千刀的墙了
//    return;
    
    GRoadSnapFacade * facade = [[GRoadSnapFacade alloc] init];
    facade.snapPath = rawRoute;
    facade.interpolate = YES;
    [facade requestWithSuccess:^(NSArray * snapRoute) {
        NSLog(@"update snap path");
        [self updateMapWithSnapRoute:snapRoute];
        //[self updateWayPointData:snapRoute];
    } failure:^(NSError * err) {
        NSLog(@"GRoadSnapFacade err = %@", err);
    }];
}

- (void)updateMapWithSnapRoute:(NSArray*)routes
{
    [self.mapView removeOverlays:self.mapView.overlays];
    
    if (routes.count > 1)
    {
        MKCoordinateRegion region;
        
        CLLocationDegrees maxLat = -90;
        CLLocationDegrees maxLon = -180;
        CLLocationDegrees minLat = 90;
        CLLocationDegrees minLon = 180;
        
        CLLocationCoordinate2D pointsToUse[routes.count];
        for (int i = 0; i < routes.count; i++)
        {
            GSnapPtModel * item = routes[i];

            CLLocationCoordinate2D marsCoords = [item coordinate];
            pointsToUse[i] = marsCoords;

            if(marsCoords.latitude > maxLat)
                maxLat = marsCoords.latitude;
            if(marsCoords.latitude < minLat)
                minLat = marsCoords.latitude;
            if(marsCoords.longitude > maxLon)
                maxLon = marsCoords.longitude;
            if(marsCoords.longitude < minLon)
                minLon = marsCoords.longitude;

            MKCircle * circle = [MKCircle circleWithCenterCoordinate:marsCoords radius:8];
            circle.title = @"ErrCircle";
            [self.mapView addOverlay:circle];
        }
        
        MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:routes.count];
        lineOne.title = @"allLine";
        [self.mapView addOverlay:lineOne];
        
        region.center.latitude     = (maxLat + minLat) / 2;
        region.center.longitude    = (maxLon + minLon) / 2;
        region.span.latitudeDelta  = maxLat - minLat + 0.018;
        region.span.longitudeDelta = maxLon - minLon + 0.018;
        [self.mapView setRegion:region animated:YES];
    }
}

- (void)updateTripInfo
{
    if (self.tripSum)
    {
        NSMutableArray * regions = [NSMutableArray array];
        GPSEventItem * stRegion = [[GPSLogger sharedLogger].dbLogger selectLatestEventBefore:self.tripSum.start_date ofType:eGPSEventExitRegion];
        if (nil == stRegion) {
            stRegion = [[GPSLogger sharedLogger].dbLogger selectLatestEventBefore:self.tripSum.start_date ofType:eGPSEventMonitorRegion];
        }
        GPSEventItem * edRegion = [[GPSLogger sharedLogger].dbLogger selectLatestEventAfter:self.tripSum.end_date ofType:eGPSEventMonitorRegion];
        if (stRegion) [regions addObject:stRegion];
        if (edRegion) [regions addObject:edRegion];
        self.monitorRegions = regions;
        
        NSArray * logArr = [[GPSLogger sharedLogger].dbLogger selectLogFrom:self.tripSum.start_date toDate:self.tripSum.end_date offset:0 limit:0];
        NSMutableArray * logs = [NSMutableArray array];
        if (stRegion && logArr.count > 0) {
            GPSLogItem * stItem = [[GPSLogItem alloc] initWithEventItem:stRegion];
            if (stItem) {
                // check the modified start point is valid
                GPSLogItem * item = logArr[0];
                CLLocation * curLoc = [[CLLocation alloc] initWithLatitude:[item.latitude doubleValue] longitude:[item.longitude doubleValue]];
                CLLocation * lastLoc = [[CLLocation alloc] initWithLatitude:[stItem.latitude doubleValue] longitude:[stItem.longitude doubleValue]];
                CLLocationDistance distance = [lastLoc distanceFromLocation:curLoc];
                if (distance < cStartLocErrorDist) {
                    // the modified start point is valid, add to array
                    [logs addObject:stItem];
                }
            }
        }
        [logs addObjectsFromArray:logArr];
        self.gpsLogs = logs;
        
        [self.mapView reloadInputViews];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) updateRouteView:(NSArray*)gpsLog
{
    [self.mapView removeOverlays:self.mapView.overlays];
    
//    NSArray * parkingRegions = [[TripsCoreDataManager sharedManager] mostUsefulTripsLimit:0];
//    for (RegionGroup * group in parkingRegions)
//    {
//        CLLocationCoordinate2D coordsSt = CLLocationCoordinate2DMake([group.start_region.center_lat floatValue], [group.start_region.center_lon floatValue]);
//        CLLocationCoordinate2D coordsEd = CLLocationCoordinate2DMake([group.end_region.center_lat floatValue], [group.end_region.center_lon floatValue]);
//        MKCircle * circleSt = [MKCircle circleWithCenterCoordinate:[GeoTransformer earth2Mars:coordsSt] radius:cRegionRadiusThreshold];
//        circleSt.title = @"parkingRegion";
//        [self.mapView addOverlay:circleSt];
//        MKCircle * circleEd = [MKCircle circleWithCenterCoordinate:[GeoTransformer earth2Mars:coordsEd] radius:cRegionRadiusThreshold];
//        circleEd.title = @"parkingRegion";
//        [self.mapView addOverlay:circleEd];
//    }
    
    if (gpsLog.count > 1)
    {
        MKCoordinateRegion region;
        
        CLLocationDegrees maxLat = -90;
        CLLocationDegrees maxLon = -180;
        CLLocationDegrees minLat = 90;
        CLLocationDegrees minLon = 180;
        
        CLLocationCoordinate2D pointsToUse[gpsLog.count];
        int realCnt = 0;
        BOOL isJam = NO;
        //GPSLogItem * last = [gpsLog lastObject];
        for (int i = 0; i < gpsLog.count; i++)
        {
            GPSLogItem * item = gpsLog[i];
            
            if ([item.horizontalAccuracy doubleValue] > 1000) {
                continue;
            }
            
            CLLocationCoordinate2D coords;
            coords.latitude = [item.latitude doubleValue];
            coords.longitude = [item.longitude doubleValue];
            CLLocationCoordinate2D marsCoords = [GeoTransformer earth2Mars:coords];
            CGFloat curSpeed = ([item.speed floatValue] < 0 ? 0 : [item.speed floatValue]);
            
            if([item.latitude doubleValue] > maxLat)
                maxLat = [item.latitude doubleValue];
            if([item.latitude doubleValue] < minLat)
                minLat = [item.latitude doubleValue];
            if([item.longitude doubleValue] > maxLon)
                maxLon = [item.longitude doubleValue];
            if([item.longitude doubleValue] < minLon)
                minLon = [item.longitude doubleValue];
            
            // travel route and traffic jam route
            pointsToUse[realCnt++] = marsCoords;
            if (!isJam && curSpeed <= cAvgTrafficJamSpeed) {
                MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:realCnt];
                lineOne.title = @"allLine";
                [self.mapView addOverlay:lineOne];
                realCnt = 0;
                pointsToUse[realCnt++] = marsCoords;
            } else if (isJam && curSpeed > cAvgTrafficJamSpeed) {
                MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:realCnt];
                lineOne.title = @"allLine";
                [self.mapView addOverlay:lineOne];
                realCnt = 0;
                pointsToUse[realCnt++] = marsCoords;
            }
            isJam = curSpeed <= cAvgTrafficJamSpeed ? YES : NO;
            
            MKCircle * circle = [MKCircle circleWithCenterCoordinate:marsCoords radius:[item.horizontalAccuracy doubleValue]];
            circle.title = @"ErrCircle";
            [self.mapView addOverlay:circle];
            
            if (i > 0) {
                // break or accelerate
//                if ([last distanceFrom:item] > 30 && [last.timestamp timeIntervalSinceDate:item.timestamp] >= 10 && [item.horizontalAccuracy doubleValue] <= 1000) {
//                    GPSLogItem * lastItem = gpsLog[i-1];
//                    CGFloat xDif = fabs([item.accelerationX doubleValue]-[lastItem.accelerationX doubleValue]);
//                    CGFloat yDif = fabs([item.accelerationY doubleValue]-[lastItem.accelerationY doubleValue]);
//                    CGFloat zDif = fabs([item.accelerationZ doubleValue]-[lastItem.accelerationZ doubleValue]);
//                    CGFloat mod = xDif + yDif + zDif;
//                    
//                    MKCircle * circle = nil;
//                    if (mod > 0.4) {
//                        circle = [MKCircle circleWithCenterCoordinate:marsCoords radius:10];
//                    } else if (mod > 0.2) {
//                        circle = [MKCircle circleWithCenterCoordinate:marsCoords radius:5];
//                    }
//                    if (circle) {
//                        if ([item.speed doubleValue] > [lastItem.speed doubleValue]) {
//                            circle.title = @"MoveForward";
//                        } else {
//                            circle.title = @"MoveBackward";
//                        }
//                        [self.mapView addOverlay:circle];
//                    }
//                }

                // terbulence location
//                CGFloat threshold = .7;
//                if ((xDif > threshold && yDif > threshold) ||
//                    (xDif > threshold && zDif > threshold) ||
//                    (yDif > threshold && zDif > threshold)) {
//                    circle = [MKCircle circleWithCenterCoordinate:marsCoords radius:20];
//                    circle.title = @"MoveBackward";
//                    [self.mapView addOverlay:circle];
//                }
                
                // altitude change
                
            }
        }

        MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:realCnt];
        lineOne.title = isJam ? @"jamLine" : @"allLine";
        [self.mapView addOverlay:lineOne];
        
        for (GPSEventItem * item in self.monitorRegions) {
            CLLocationCoordinate2D coords;
            coords.latitude = [item.latitude doubleValue];
            coords.longitude = [item.longitude doubleValue];
            CLLocationCoordinate2D marsCoords = [GeoTransformer earth2Mars:coords];
            MKCircle * circle = [MKCircle circleWithCenterCoordinate:marsCoords radius:[item.radius doubleValue]];
            circle.title = @"MonitorRegion";
            [self.mapView addOverlay:circle];
        }
        
        region.center.latitude     = (maxLat + minLat) / 2;
        region.center.longitude    = (maxLon + minLon) / 2;
        region.span.latitudeDelta  = maxLat - minLat + 0.018;
        region.span.longitudeDelta = maxLon - minLon + 0.018;
        [self.mapView setRegion:region animated:YES];
    }
    
    NSInteger heavyJam = 0;
    NSArray * jamArr =  [self.tripSum.traffic_jams allObjects];
    for (TrafficJam * jamPair in jamArr)
    {
        CLLocationCoordinate2D pointsToUse[2];
        
        CLLocationCoordinate2D coords;
        coords.latitude = [jamPair.start_lat doubleValue];
        coords.longitude = [jamPair.start_lon doubleValue];
        CLLocationCoordinate2D marsCoords = [GeoTransformer earth2Mars:coords];
        pointsToUse[0] = marsCoords;
        
        coords.latitude = [jamPair.end_lat doubleValue];
        coords.longitude = [jamPair.end_lon doubleValue];
        marsCoords = [GeoTransformer earth2Mars:coords];
        pointsToUse[1] = marsCoords;
        
        MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:2];
        lineOne.title = @"jamLine";

        if (jamPair.end_date && jamPair.start_date && [jamPair.end_date timeIntervalSinceDate:jamPair.start_date] > cHeavyTrafficJamThreshold) {
            lineOne.title = @"heavyJamLine";
            heavyJam++;
        }
        
        [self.mapView addOverlay:lineOne];
    }
    
    // draw turning point
    NSData * ptsData = self.tripSum.turning_info.addi_data;
    if (ptsData) {
        NSArray * pts = [NSKeyedUnarchiver unarchiveObjectWithData:ptsData];
        for (NSDictionary * first in pts) {
            CLLocationCoordinate2D coords = CLLocationCoordinate2DMake([first[@"lat"] doubleValue], [first[@"lon"] doubleValue]);
            CLLocationCoordinate2D marsCoords = [GeoTransformer earth2Mars:coords];
            MKCircle * circle = [MKCircle circleWithCenterCoordinate:marsCoords radius:15];
            circle.title = @"MoveForward";
            [self.mapView addOverlay:circle];
        }
    }
    
    //NSLog(@"traffic light = %@, total jam = %@, light jam = %@, heavy jam = %ld", _tripSum.traffic_light_tol_cnt, _tripSum.traffic_heavy_jam_cnt, _tripSum.traffic_light_jam_cnt, (long)heavyJam);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline * line = (MKPolyline*)overlay;
        MKPolylineRenderer * lineRender=[[MKPolylineRenderer alloc] initWithOverlay:overlay] ;
        if ([line.title isEqualToString:@"allLine"]) {
            lineRender.strokeColor = [UIColor colorWithRed:69.0f/255.0f green:212.0f/255.0f blue:255.0f/255.0f alpha:0.9];
        } else if ([line.title isEqualToString:@"jamLine"]) {
            lineRender.strokeColor = [UIColor colorWithRed:168.0f/255.0f green:12.0f/255.0f blue:155.0f/255.0f alpha:0.9];
        } else if ([line.title isEqualToString:@"heavyJamLine"]) {
            lineRender.strokeColor = [UIColor colorWithRed:255.0f/255.0f green:12.0f/255.0f blue:55.0f/255.0f alpha:0.9];
        }
        lineRender.lineWidth = 4.0;
        return lineRender;
    } else if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircle * circle = (MKCircle*)overlay;
        MKCircleRenderer * circleRender=[[MKCircleRenderer alloc] initWithOverlay:overlay] ;
        if ([circle.title isEqualToString:@"MonitorRegion"]) {
            circleRender.strokeColor=[UIColor colorWithRed:55.0f/255.0f green:252.0f/255.0f blue:155.0f/255.0f alpha:0.9];
        } else if ([circle.title isEqualToString:@"ErrCircle"]) {
            circleRender.strokeColor=[UIColor colorWithRed:255.0f/255.0f green:112.0f/255.0f blue:155.0f/255.0f alpha:0.9];
        } else if ([circle.title isEqualToString:@"MoveForward"]) {
            circleRender.strokeColor=[UIColor colorWithRed:12.0f/255.0f green:255.0f/255.0f blue:155.0f/255.0f alpha:0.9];
        } else if ([circle.title isEqualToString:@"MoveBackward"]) {
            circleRender.strokeColor=[UIColor colorWithRed:22.0f/255.0f green:22.0f/255.0f blue:15.0f/255.0f alpha:0.9];
        } else if ([circle.title isEqualToString:@"parkingRegion"]) {
            circleRender.strokeColor=[UIColor colorWithRed:232.0f/255.0f green:232.0f/255.0f blue:15.0f/255.0f alpha:1.0];
        }
        circleRender.lineWidth = 3.0;
        return circleRender;
    }

    return nil;
}

- (IBAction)switchMap:(UIBarButtonItem*)sender
{
}

- (IBAction)close:(id)sender {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
