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
#import "POICategory.h"
#import "UIImage+RZSolidColor.h"
#import "CTPOICategoryFacade.h"

@interface CarAssistorViewController () {
    ZBNSearchDisplayController *       searchDisplayController;
}

@property (nonatomic, strong) NSArray *                         topNMostUsedTrips;
@property (nonatomic, strong) NSArray *                         topNMostParkingLoc;
@property (nonatomic, strong) SearchPOIHeader*                  header;
@property (nonatomic, strong) NSArray *                         categories;
@property (nonatomic) NSUInteger                                selCategoryIdx;

@end

@implementation CarAssistorViewController

- (void)internalInit
{
    self.categories = [[CTPOICategoryFacade new] defaultCategorys];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
    _searchBar.translucent = YES;
    _searchBar.placeholder = @"搜索要去的地名                     ";
    _searchBar.barTintColor = [UIColor clearColor];
    _searchBar.backgroundColor = [UIColor clearColor];
    [self.searchBar setSearchFieldBackgroundImage:[UIImage rz_solidColorImageWithSize:CGSizeMake(28, 28) color:[UIColor clearColor]] forState:UIControlStateNormal];
    [_searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    
    searchDisplayController = [[ZBNSearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    searchDisplayController.delegate = self;
    
    [_searchBar setImage:[UIImage new] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    _searchBar.searchTextPositionAdjustment = UIOffsetMake(8, 0);
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:UIColorFromRGB(0xaaaaaa)];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{
                                                                                                 NSFontAttributeName: [UIFont boldSystemFontOfSize:14],
                                                                                                 NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.2]
                                                                                                 }];
    [self reloadContent];
}

- (void)updateData
{
    CTPOICategoryFacade * poiFacade = [CTPOICategoryFacade new];
    [poiFacade requestWithSuccess:^(id array) {
        self.categories = array;
    } failure:nil];
}

- (void)reloadContent
{
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (curLoc) {
        ParkingRegionDetail * parkingDetail = [[AnaDbManager sharedInst] parkingDetailForCoordinate:curLoc.coordinate];
        self.topNMostUsedTrips = [[AnaDbManager sharedInst] tripsWithStartRegion:parkingDetail.coreDataItem tripLimit:3];
    }
    self.topNMostParkingLoc = [[AnaDbManager sharedInst] mostUsedParkingRegionLimit:20];
    
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

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.header.rightIcon.hidden = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.header.rightIcon.hidden = NO;
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
        return 3;
    } else if (1 == section) {
        if (0 == _selCategoryIdx) {
            return self.topNMostParkingLoc.count + 1;
        }
        return 4;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = nil;
    if (0 == indexPath.section)
    {
        if (indexPath.row < self.topNMostUsedTrips.count) {
            DriveSuggestCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"suggestUsefulCell" forIndexPath:indexPath];
            [realCell updateWithTripSummary:self.topNMostUsedTrips[indexPath.row]];
            realCell._rz_parentCollectionTableView = self.suggestCollectionView;
            RZCollectionTableViewCellEditingItem * delItem = [RZCollectionTableViewCellEditingItem itemWithIcon:[UIImage imageNamed:@"deleteicon"] highlightedIcon:[UIImage imageNamed:@"deleteicon"] backgroundColor:[UIColor clearColor] hostBgImg:[UIImage imageNamed:@"deletetag"]];
            [realCell setRzEditingItems:@[delItem]];
            realCell.rzEditingEnabled = YES;
            cell = realCell;
        } else {
            UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"suggestNewCell" forIndexPath:indexPath];
            cell = realCell;
        }
    }
    else
    {
        if (0 == indexPath.row) {
            SuggestPOICategoryCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestPOIFirst" forIndexPath:indexPath];
            NSMutableArray * strArr = [NSMutableArray array];
            for (POICategory * cat in self.categories) {
                [strArr addObject:cat.disp_name];
            }
            realCell.scrollSeg.segStrings = strArr;
            realCell.scrollSeg.selIdx = _selCategoryIdx;
            
            __block CarAssistorViewController * weakSelf = self;
            [realCell.scrollSeg setSelBlock:^(NSUInteger selIdx) {
                weakSelf.selCategoryIdx = selIdx;
                [weakSelf.suggestCollectionView reloadSections:[NSIndexSet indexSetWithIndex:1]];
            }];
            
            cell = realCell;
        } else {
            DriveSuggestPOICell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestPOICell" forIndexPath:indexPath];
            if (0 == _selCategoryIdx) {
                [realCell updateWithLocation:self.topNMostParkingLoc[indexPath.row-1]];
            } else {
                [realCell useMockData];
            }
            cell = realCell;
        }
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView* reusableView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        self.header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SuggestPOIHeader" forIndexPath:indexPath];
        _searchBar.center = CGPointMake(self.header.backgroundMask.bounds.size.width/2.0, self.header.backgroundMask.bounds.size.height/2.0);
        [self.header.backgroundMask addSubview:_searchBar];
        reusableView = self.header;
    }
    
    return reusableView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.section) {
        return CGSizeMake(300.f, 65.f);
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
    return 0.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (0 == section) {
        return UIEdgeInsetsMake(5.f, 0, 0, 0);
    } else if (1 == section) {
        return UIEdgeInsetsMake(15.f, 0, 0, 0);
    }
    return UIEdgeInsetsZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
{
    if (0 == section) {
        return CGSizeMake(320, 80);
    }
    return CGSizeZero;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        if (indexPath.row < self.topNMostUsedTrips.count) {
            SuggestDetailViewController * suggestDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestDetailID"];
            suggestDetail.tripSum = self.topNMostUsedTrips[indexPath.row];
            [self.navigationController pushViewController:suggestDetail animated:YES];
        } else {
            [self showToast:@"自定义添加功能尚在开发中"];
        }
        
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
