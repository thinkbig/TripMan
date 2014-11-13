//
//  LocationViewController.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "LocationViewController.h"
#import "GPSLogger.h"
#import "TripDetailViewController.h"
#import "MapDisplayViewController.h"
#import "NSDate+Utilities.h"

@interface LocationViewController ()

@property (nonatomic, retain) NSArray *         anaResult;
@property (nonatomic, retain) NSIndexPath *     idxPath;

@end

@implementation LocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    UIViewController* vc = (UIViewController *)[segue destinationViewController];
    if ([vc isKindOfClass:[TripDetailViewController class]])
    {
        NSIndexPath *indexPath = [self.contentTable indexPathForSelectedRow];
        TripDetailViewController * detailVC = (TripDetailViewController*)vc;
        detailVC.analyzeSum = self.anaResult[indexPath.row];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.anaResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"AnaCellId" forIndexPath:indexPath];
    UILabel * contentLabel = (UILabel*)[cell.contentView viewWithTag:1000];
    
    TripSummary * sum = self.anaResult[indexPath.row];
    contentLabel.text = [NSString stringWithFormat:@"from: %@-%@-%@, to:%@-%@-%@, dist=%@, during=%@, max_speed=%@, jam_during=%@", sum.start_date, sum.region_group.start_region.street, sum.region_group.start_region.nearby_poi, sum.end_date, sum.region_group.end_region.street, sum.region_group.end_region.nearby_poi, sum.total_dist, sum.total_during, sum.max_speed, sum.traffic_jam_during];
    
    return cell;
}

- (IBAction)refresh:(id)sender
{
    // only transport finished trips
    
//    NSArray * finishedTrips = [[GPSLogger sharedLogger].offTimeAnalyzer old_analyzedResultFrom:nil toDate:nil offset:0 limit:0 reverseOrder:YES forceAnalyze:NO];
//    for (GPSAnalyzeSumItem * item in finishedTrips) {
//        NSArray * tripExist = [[TripsCoreDataManager sharedManager] tripStartFrom:item.start_date toDate:item.start_date];
//        if (tripExist.count == 0) {
//            [[TripsCoreDataManager sharedManager] newTripAt:item.start_date endAt:item.end_date];            
//        }
//    }
//    [[TripsCoreDataManager sharedManager] commit];
    
    NSArray * coreSum = [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripStartFrom:nil toDate:nil];
    [[BussinessDataProvider sharedInstance] updateAllRegionInfo:NO];
    self.anaResult = coreSum;
    [self.contentTable reloadData];
}

- (IBAction)closeDebug:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
