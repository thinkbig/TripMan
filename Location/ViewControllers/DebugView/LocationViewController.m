//
//  LocationViewController.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "LocationViewController.h"
#import "GPSLogger.h"
#import "DataReporter.h"
#import "JamDisplayViewController.h"

@implementation LocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.uidLabel.text = [NSString stringWithFormat:@"uid: %@", [[GToolUtil sharedInstance] userId]];
    self.udidLabel.text = [NSString stringWithFormat:@"udid: %@", [[GToolUtil sharedInstance] deviceId]];
    self.envLabel.text = [NSString stringWithFormat:@"env: %@ - isWifi(%d)", kChetuBaseUrl, IS_WIFI];
    
    UITapGestureRecognizer * tapUid = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUid)];
    [self.uidLabel addGestureRecognizer:tapUid];
    
    UITapGestureRecognizer * tapUdid = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUdid)];
    [self.udidLabel addGestureRecognizer:tapUdid];
    
    UITapGestureRecognizer * tapReport = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(updateReport)];
    [self.reportLabel addGestureRecognizer:tapReport];
    
    [self updateReport];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
}

- (IBAction)closeDebug:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)forceReport:(id)sender {
    [[DataReporter sharedInst] forceAsync];
}

- (IBAction)reAnalyzeTrip:(id)sender {
    [self showLoading];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeAllFinishedTrip:YES];
        [self hideLoading];
    });
}

- (IBAction)toJamMap:(id)sender {
    JamDisplayViewController * jamVC = [self.storyboard instantiateViewControllerWithIdentifier:@"JamDisplayVC"];
    [self.navigationController pushViewController:jamVC animated:YES];
}

- (void) updateReport {
    TripsCoreDataManager * manager = [AnaDbManager deviceDb];
    NSString * report = [NSString stringWithFormat:@"尚未上报：停车位置(%ld)  旅程详情(%ld)  原始gps(%ld)", (unsigned long)[manager parkingRegionsToReport:NO].count, (unsigned long)[manager tripsReadyToReport:NO].count, (unsigned long)[manager tripRawsReadyToReport].count];
    self.reportLabel.text = report;
}

- (void) tapUid {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [[GToolUtil sharedInstance] userId];
    [self showToast:@"uid 已经拷贝到剪切板" onDismiss:nil];
}

- (void) tapUdid {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [[GToolUtil sharedInstance] deviceId];
    [self showToast:@"udid 已经拷贝到剪切板" onDismiss:nil];
}

@end
