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

@implementation LocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.uidLabel.text = [NSString stringWithFormat:@"uid: %@", [GToolUtil userId]];
    self.udidLabel.text = [NSString stringWithFormat:@"udid: %@", [GToolUtil deviceId]];
    self.envLabel.text = [NSString stringWithFormat:@"env: %@", kChetuBaseUrl];
    
    UITapGestureRecognizer * tapUid = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUid)];
    [self.uidLabel addGestureRecognizer:tapUid];
    
    UITapGestureRecognizer * tapUdid = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUdid)];
    [self.udidLabel addGestureRecognizer:tapUdid];
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

- (void) tapUid {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [GToolUtil userId];
    [self showToast:@"uid 已经拷贝到剪切板"];
}

- (void) tapUdid {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [GToolUtil deviceId];
    [self showToast:@"udid 已经拷贝到剪切板"];
}

@end
