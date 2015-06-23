//
//  BaiduMapViewController.m
//  TripMan
//
//  Created by taq on 3/26/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "BaiduMapViewController.h"
#import "RouteAnnotation.h"
#import "GPSOffTimeFilter.h"
#import "GeoRectBound.h"
#import "GeoTransformer.h"
#import "TrafficJam+Fetcher.h"
#import "NSDate+Utilities.h"
#import "TrafficJam+Fetcher.h"
#import "RouteOverlayView.h"

@interface BaiduMapViewController ()

@property (nonatomic, strong) NSArray *         locationArr;

@end

@implementation BaiduMapViewController

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
    
    if ([GToolUtil isEnableDebug]) {
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:self.tripSum withAnalyzer:nil];
    }
    
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
    [self.fullTurningAnno removeAllObjects];
    
    NSArray * steps = route.steps;
    GeoRectBound * regionBound = [GeoRectBound new];
    
    NSMutableArray * jams2Add = [NSMutableArray array];
    NSMutableArray * route2Add = [NSMutableArray array];
    NSString * lastSubTitle = @"dash";
    CGFloat lastDegree = 0;
    CLLocationCoordinate2D lastCoor = CLLocationCoordinate2DMake(0, 0);
    for (CTStep * oneStep in steps)
    {
        CLLocationCoordinate2D bdCoorFrom = [GeoTransformer baiduCoor:[oneStep.from coordinate] fromType:coorType];
        [regionBound updateBoundsWithCoor:bdCoorFrom];
        
        CLLocationCoordinate2D btCoorTo = [GeoTransformer baiduCoor:[oneStep.to coordinate] fromType:coorType];
        [regionBound updateBoundsWithCoor:btCoorTo];
        
        NSArray * pathArr = [oneStep pathArray];

        // 转弯节点添加标注
        RouteAnnotation* itemNode = [[RouteAnnotation alloc] init];
        itemNode.coordinate = bdCoorFrom;
        itemNode.degree = [BaiduHelper mapAngleFromPoint:CGPointMake(bdCoorFrom.longitude, bdCoorFrom.latitude) toPoint:CGPointMake(btCoorTo.longitude, btCoorTo.latitude)];
        itemNode.type = 2;
        [self.fullTurningAnno addObject:itemNode];
        lastDegree = itemNode.degree;
        lastCoor = btCoorTo;
        
        NSString * subTitle = @"solid";
        if (pathArr.count < 3 && [oneStep.from.ts timeIntervalSinceDate:route.orig.ts] < 60*5) {
            if (route.orig) {
                if ([oneStep.to distanceFrom:route.orig] < 400) {
                    subTitle = @"dash";   // too close to start loc, just ignore
                } else if ([oneStep.from distanceFrom:route.orig] < 100) {
                    subTitle = @"dash";
                }
            }
        }
        
        if (![lastSubTitle isEqualToString:subTitle] && route2Add.count > 0) {
            BMKMapPoint * pointsToUse = new BMKMapPoint[route2Add.count];
            [route2Add enumerateObjectsUsingBlock:^(CTBaseLocation * loc, NSUInteger idx, BOOL *stop) {
                CLLocationCoordinate2D btCoor = [GeoTransformer baiduCoor:[loc coordinate] fromType:coorType];
                BMKMapPoint bdMappt = BMKMapPointForCoordinate(btCoor);
                pointsToUse[idx] = bdMappt;
            }];
            
            RouteOverlay * lineOne = [RouteOverlay routeWithPoints:pointsToUse count:route2Add.count];
            lineOne.title = @"green";
            lineOne.subtitle = lastSubTitle;
            [self.mapView addOverlay:lineOne];
            
            delete [] pointsToUse;
            [route2Add removeAllObjects];
            lastSubTitle = subTitle;
        }
        
        [route2Add addObject:oneStep.from];
        if (pathArr.count > 0) {
            [route2Add addObjectsFromArray:pathArr];
        }
        [route2Add addObject:oneStep.to];
        
        // 处理堵车数据
        CLLocation * origLoc = [route.orig clLocation];
        CLLocation * destLoc = [route.dest clLocation];
        NSArray * filteredJamArr = [oneStep jamsWithThreshold:cTrafficJamThreshold];
        for (CTJam * jam in filteredJamArr) {
            if ([jam.from.ts timeIntervalSinceDate:route.orig.ts] < 60*5 || [route.dest.ts timeIntervalSinceDate:jam.to.ts] < 60*5) {
                [jam calCoefWithStartLoc:origLoc andEndLoc:destLoc];
            }
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
                [jams2Add addObject:jamOne];
                
                delete [] jamsToUse;
            }
        }
    }
    
    if (route2Add.count > 0) {
        BMKMapPoint * pointsToUse = new BMKMapPoint[route2Add.count];
        [route2Add enumerateObjectsUsingBlock:^(CTBaseLocation * loc, NSUInteger idx, BOOL *stop) {
            CLLocationCoordinate2D btCoor = [GeoTransformer baiduCoor:[loc coordinate] fromType:coorType];
            BMKMapPoint bdMappt = BMKMapPointForCoordinate(btCoor);
            pointsToUse[idx] = bdMappt;
        }];

        RouteOverlay * lineOne = [RouteOverlay routeWithPoints:pointsToUse count:route2Add.count];
        lineOne.title = @"green";
        lineOne.subtitle = lastSubTitle;
        [self.mapView addOverlay:lineOne];
        
        delete [] pointsToUse;
    }
    
    for (RouteOverlay * jamOne in jams2Add) {
        [self.mapView addOverlay:jamOne];
    }
    
    RouteAnnotation* itemNode = [[RouteAnnotation alloc] init];
    itemNode.coordinate = lastCoor;
    itemNode.degree = lastDegree;
    itemNode.type = 2;
    [self.fullTurningAnno addObject:itemNode];
    
    CTBaseLocation * startLoc = route.orig;
    CTBaseLocation * endLoc = route.dest;
    
    RouteAnnotation* itemSt = [[RouteAnnotation alloc] init];
    itemSt.coordinate = [GeoTransformer baiduCoor:[startLoc coordinate] fromType:coorType];
    itemSt.title = @"起点";
    itemSt.type = 0;
    [self.mapView addAnnotation:itemSt];
    [regionBound updateBoundsWithCoor:itemSt.coordinate];
    
    RouteAnnotation* itemEd = [[RouteAnnotation alloc] init];
    itemEd.coordinate = [GeoTransformer baiduCoor:[endLoc coordinate] fromType:coorType];
    itemEd.title = @"终点";
    itemEd.type = 1;
    [self.mapView addAnnotation:itemEd];
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

@end
