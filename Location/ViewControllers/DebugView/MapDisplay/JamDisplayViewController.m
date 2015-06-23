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
#import "STAlertView.h"
#import "TripFetchFacade.h"

typedef NS_ENUM(NSUInteger, eDispMapType) {
    eDispMapTypeJam = 0,
    eDispMapTypeTest,
    eDispMapTypeTrip,
};

@interface JamDisplayViewController ()

@property (nonatomic, strong) BaiduHelper *     bdHelper;
@property (nonatomic) eDispMapType              dispType;
@property (nonatomic, strong) NSString *        requestKey;
@property (nonatomic, strong) STAlertView *     alertView;

@end

@implementation JamDisplayViewController

- (NSString *)requestKey {
    if (nil == _requestKey) {
        _requestKey = @"";
    }
    return _requestKey;
}

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
    BMKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self requestJamWithZone];
    });
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSecret)];
    tapGesture.numberOfTapsRequired = 2;
    [self.navigationController.navigationBar addGestureRecognizer:tapGesture];
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

- (void)tapSecret
{
    self.alertView = [[[STAlertView alloc] initWithTitle:@"RequestKey"
                                               message:@"Input Request Key"
                                         textFieldHint:@"RequestKey"
                                        textFieldValue:self.requestKey
                                     cancelButtonTitle:@"取消"
                                      otherButtonTitle:@"确定"
                                     cancelButtonBlock:nil otherButtonBlock:^(NSString * result){
                                         self.requestKey = result;
                                         [self showToast:[NSString stringWithFormat:@"RequestKey = %@", result] onDismiss:nil];
                                         [self reloadData:YES];
                                     }] show];
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
    [ActionSheetStringPicker showPickerWithTitle:@"选择要显示的内容" rows:@[@"实时拥堵地图", @"路径拆分", @"显示trip"] initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        self.title = selectedValue;
        if (0 == selectedIndex) {
            self.dispType = eDispMapTypeJam;
            [self requestJamWithZone];
        } else if (1 == selectedIndex) {
            self.dispType = eDispMapTypeTest;
            [self requestTestDataWithZone];
        } else if (2 == selectedIndex) {
            self.dispType = eDispMapTypeTrip;
            [self requestTripData];
        }
    } cancelBlock:nil origin:self.view];
}

- (void) reloadData:(BOOL)force {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (eDispMapTypeJam == self.dispType) {
            [self requestJamWithZone];
        } else if (eDispMapTypeTest == self.dispType) {
            [self requestTestDataWithZone];
        } else if (eDispMapTypeTrip == self.dispType && force) {
            [self requestTripData];
        }
    });
}

- (void) requestTripData
{
    if (self.requestKey.length < 8) {
        [self showToast:@"不是有效的tripId" onDismiss:nil];
    }
    TripFetchFacade * facade = [TripFetchFacade new];
    facade.tripId = self.requestKey;
    [facade requestWithSuccess:^(CTTrip * trip) {
        [self updateRouteViewWithRoute:trip.route coorType:eCoorTypeGps];
    } failure:^(NSError * err) {
        NSLog(@"err = %@", err);
    }];
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

- (void) requestJamWithZone
{
    GeoRectBound * bound = [BaiduHelper getBoundingBox:self.mapView.visibleMapRect];

    CTRealtimeJamFacade * facade = [[CTRealtimeJamFacade alloc] init];
    facade.geoBound = bound;
    [facade request:@{@"key":self. requestKey} success:^(NSArray * jamArr) {
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
        [self.mapView addAnnotation:itemNode];
        
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
    [facade request:@{@"key":self. requestKey} success:^(NSArray * jamArr) {
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
    if ([overlay isKindOfClass:[BMKCircle class]])
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
    
    if (nil == overlayView) {
        overlayView = [super mapView:mapView viewForOverlay:overlay];
    }
    return overlayView;
}

- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [super mapView:mapView regionDidChangeAnimated:animated];
    [self reloadData:NO];
}

@end
