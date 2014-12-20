//
//  CarAssistorViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarAssistorViewController.h"
#import "DriveSuggestCell.h"
#import "MapDisplayViewController.h"
#import "SuggestDetailViewController.h"
#import "RZCollectionTableView_Private.h"
#import "ZBNSearchDisplayController.h"

@interface CarAssistorViewController () {
    ZBNSearchDisplayController *       searchDisplayController;
}

@property (nonatomic, strong) NSArray *                         topNMostUsedTrips;

@end

@implementation CarAssistorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 220, 44)];
    _searchBar.translucent = YES;
    _searchBar.placeholder = @"输入要去的地名";
    _searchBar.barTintColor = [UIColor clearColor];
    _searchBar.backgroundColor = [UIColor clearColor];
    [_searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    
    searchDisplayController = [[ZBNSearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    
    [self reloadContent];
}

- (void)reloadContent
{
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (curLoc) {
        ParkingRegionDetail * parkingDetail = [[TripsCoreDataManager sharedManager] parkingDetailForCoordinate:curLoc.coordinate];
        self.topNMostUsedTrips = [[TripsCoreDataManager sharedManager] tripsWithStartRegion:parkingDetail.coreDataItem tripLimit:3];
    }
    
    [self.suggestCollectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [self reloadContent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    self.navigationController.navigationBar.translucent = YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.navigationController.navigationBar.translucent = NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (0 == section) {
        return self.topNMostUsedTrips.count;
    } else if (1 == section) {
        return 5;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = nil;
    if (0 == indexPath.section)
    {
        DriveSuggestCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"suggestUsefulCell" forIndexPath:indexPath];
        [realCell updateWithTripSummary:self.topNMostUsedTrips[indexPath.row]];
        realCell._rz_parentCollectionTableView = self.suggestCollectionView;
        RZCollectionTableViewCellEditingItem * delItem = [RZCollectionTableViewCellEditingItem itemWithIcon:[UIImage imageNamed:@"deleteicon"] highlightedIcon:[UIImage imageNamed:@"deleteicon"] backgroundColor:[UIColor clearColor] hostBgImg:[UIImage imageNamed:@"deletetag"]];
        [realCell setRzEditingItems:@[delItem]];
        realCell.rzEditingEnabled = YES;
        cell = realCell;
    }
    else
    {
        if (0 == indexPath.row) {
            UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestPOIFirst" forIndexPath:indexPath];
            
            cell = realCell;
        } else {
            UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestPOICell" forIndexPath:indexPath];
            
            cell = realCell;
        }
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView* reusableView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        SearchPOIHeader* header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SuggestPOIHeader" forIndexPath:indexPath];
        _searchBar.center = CGPointMake(header.backgroundMask.bounds.size.width/2.0, header.backgroundMask.bounds.size.height/2.0);
        [header.backgroundMask addSubview:_searchBar];
        reusableView = header;
    }
    
    return reusableView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.section) {
        return CGSizeMake(300.f, 70.f);
    } else if (1 == indexPath.section) {
        if (0 == indexPath.row) {
            return CGSizeMake(320, 40);
        } else {
            return CGSizeMake(320, 70);
        }
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if (0 == section) {
        return 10.f;
    }
    return 1.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(10.f, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
{
    if (0 == section) {
        return CGSizeMake(320, 90);
    }
    return CGSizeZero;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        SuggestDetailViewController * suggestDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestDetailID"];
        suggestDetail.tripSum = self.topNMostUsedTrips[indexPath.row];
        [self.navigationController pushViewController:suggestDetail animated:YES];
        
//        MapDisplayViewController * mapVC = [[UIStoryboard storyboardWithName:@"Debug" bundle:nil] instantiateViewControllerWithIdentifier:@"MapDisplayView"];
//        mapVC.tripSum = self.topNMostUsedTrips[indexPath.row];
//        [self presentViewController:mapVC animated:YES completion:nil];
    }
}

- (void)collectionView:(UICollectionView *)collectionView rzTableLayout:(RZCollectionTableViewLayout *)layout editingButtonPressedForIndex:(NSUInteger)buttonIndex forRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSLog(@"delete butn idx = %ld", (long)indexPath.row);
}

@end
