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

#define OVER_HEADER_HEIGHT      114

@interface SuggestDetailViewController ()

@property (nonatomic, strong) SuggestOverLayerCollectionViewController *    overLayerVC;
@property (nonatomic, strong) NSArray *         gpsLogs;
@property (nonatomic, strong) NSArray *         jamIndex;


@end

@implementation SuggestDetailViewController

- (void)dealloc
{
    [self.overLayerVC.collectionView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    CGRect scrollFrame = self.rootScrollView.bounds;
    // add header and content
    if (nil == self.mapView) {
        self.mapView = [[MKMapView alloc] initWithFrame:scrollFrame];
        self.mapView.delegate = self;
        self.mapView.zoomEnabled = YES;
        self.mapView.scrollEnabled = YES;
        [self.rootScrollView addSubview:self.mapView withAcceleration:CGPointMake(0.0, 0.5)];
    }
    self.mapView.showsUserLocation = YES;
    
    if (nil == self.overLayerVC) {
        self.overLayerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestOverLay"];
        scrollFrame.origin.y = (scrollFrame.size.height - OVER_HEADER_HEIGHT);
        self.overLayerVC.view.frame = scrollFrame;
        self.overLayerVC.collectionView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main_bg"]];
        [self.rootScrollView addSubview:self.overLayerVC.view];
    }
    CGSize contentSize = self.rootScrollView.frame.size;
    contentSize.height = CGRectGetMaxY(scrollFrame);
    self.rootScrollView.contentSize = contentSize;
    
    [self.overLayerVC.collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    [self updateTripInfo];
    [self updateRouteView:[GPSOffTimeFilter smoothGPSData:_gpsLogs iteratorCnt:3]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateTripInfo
{
    if (self.tripSum)
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
    }
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
        
        MKCoordinateRegion region;
        
        CLLocationDegrees maxLat = -90;
        CLLocationDegrees maxLon = -180;
        CLLocationDegrees minLat = 90;
        CLLocationDegrees minLon = 180;
        
        CLLocationCoordinate2D pointsToUse[gpsLog.count];
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
            CLLocationCoordinate2D marsCoords = [GeoTransformer earth2Mars:coords];
            
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
            if (!isJam && i >= stJamIdx && i <= edJamIdx) {
                MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:realCnt];
                lineOne.title = @"allLine";
                [self.mapView addOverlay:lineOne];
                realCnt = 0;
                pointsToUse[realCnt++] = marsCoords;
                isJam = YES;
            } else if (isJam && i > edJamIdx) {
                MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:realCnt];
                TrafficJam * jamPair = jamArr[jamIdx];
                if (jamPair.end_date && jamPair.start_date && [jamPair.end_date timeIntervalSinceDate:jamPair.start_date] > cHeavyTrafficJamThreshold) {
                    lineOne.title = @"heavyJamLine";
                } else {
                    lineOne.title = @"jamLine";
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
        
        MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:realCnt];
        lineOne.title = isJam ? @"jamLine" : @"allLine";
        [self.mapView addOverlay:lineOne];

        
        region.center.latitude     = (maxLat + minLat) / 2;
        region.center.longitude    = (maxLon + minLon) / 2;
        region.span.latitudeDelta  = maxLat - minLat + 0.018;
        region.span.longitudeDelta = maxLon - minLon + 0.018;
        [self.mapView setRegion:region animated:YES];
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
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (nil != userLocation) {
        CLLocationCoordinate2D ground = userLocation.location.coordinate;
        CLLocationCoordinate2D eye = CLLocationCoordinate2DMake(ground.latitude, ground.longitude+.020);
        MKMapCamera *mapCamera = [MKMapCamera cameraLookingAtCenterCoordinate:ground
                                                            fromEyeCoordinate:eye
                                                                  eyeAltitude:700];
        
        [UIView animateWithDuration:1.0 animations:^{
            self.mapView.camera = mapCamera;
        }];
    }
}

@end
