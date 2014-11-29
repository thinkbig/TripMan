//
//  TicketDetailViewController.m
//  TripMan
//
//  Created by taq on 11/25/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "TicketDetailViewController.h"
#import "TicketDetailCell.h"

@interface TicketDetailViewController ()

@property (nonatomic, strong) NSArray *         speedSegs;

@end

@implementation TicketDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTripSum:(TripSummary *)tripSum
{
    _tripSum = tripSum;
//    GPSFMDBLogger * loggerDB = [GPSLogger sharedLogger].dbLogger;
//    NSArray * logArr = [loggerDB selectLogFrom:tripSum.start_date toDate:tripSum.end_date offset:0 limit:0];
//    
//    CGFloat during_0_30 = 0;
//    CGFloat during_30_60 = 0;
//    CGFloat during_60_100 = 0;
//    CGFloat during_100_NA = 0;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (0 == indexPath.row) {
        TicketDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DetailSummaryCell" forIndexPath:indexPath];
        [realCell setChartArr:nil];
        
        cell = realCell;
    } else if (1 == indexPath.row) {
        TicketJamDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JamDetailCell" forIndexPath:indexPath];
        
        cell = realCell;
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.row) {
        return CGSizeMake(320.f, 200.f);
    } else if (1 == indexPath.row) {
        return CGSizeMake(320.f, 150.f);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 1.0f;
}

@end
