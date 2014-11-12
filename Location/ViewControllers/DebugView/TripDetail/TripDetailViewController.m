//
//  TripDetailViewController.m
//  Location
//
//  Created by taq on 10/22/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TripDetailViewController.h"
#import "GPSLogger.h"
#import "MapDisplayViewController.h"
#import "DataDebugPrinter.h"

@implementation TripDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.sumLabel.text = [DataDebugPrinter printTripSummary:self.analyzeSum];
    self.envLabel.text = [DataDebugPrinter printEnvInfo:self.analyzeSum.environment];
    self.acceLabel.text = [DataDebugPrinter printDrivingInfo:self.analyzeSum.driving_info];
    self.turningLabel.text = [DataDebugPrinter printTurningInfo:self.analyzeSum.turning_info];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    UIViewController* vc = (UIViewController *)[segue destinationViewController];
    if ([vc isKindOfClass:[MapDisplayViewController class]])
    {
        MapDisplayViewController * mapVC = (MapDisplayViewController*)vc;
        mapVC.tripSum = self.analyzeSum;
    }
}


- (void)setAnalyzeSum:(TripSummary *)analyzeSum
{
    _analyzeSum = analyzeSum;
    if (analyzeSum) {
        [[GPSLogger sharedLogger].offTimeAnalyzer analyzeTripForSum:analyzeSum];
    }
}

@end
