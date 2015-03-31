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
#import "ParkingRegion+Fetcher.h"
#import "TripSummary+Fetcher.h"
#import "TripFilter.h"
#import "BussinessDataProvider.h"

#define kMaxUserFavLocCnt           3

@interface CarAssistorViewController () {
    ZBNSearchDisplayController *       searchDisplayController;
}

@property (nonatomic, strong) NSMutableArray *                  userFavLocs;
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
    NSArray * userFav = [[BussinessDataProvider sharedInstance] favLocations];
    if (userFav.count > 0) {
        self.userFavLocs = [NSMutableArray arrayWithArray:[userFav subarrayWithRange:NSMakeRange(0, MIN(kMaxUserFavLocCnt, userFav.count))]];
    } else {
        self.userFavLocs = [NSMutableArray array];
    }
    
    NSArray * rawRegions = [[AnaDbManager sharedInst] mostUsedParkingRegionLimit:20];
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (curLoc) {
        // 删除起点和终点过于接近的点，要求大于1500米
        NSArray * filterRegions = [TripFilter filterRegion:rawRegions byStartRegion:curLoc byDist:1500];
        self.topNMostParkingLoc = filterRegions;

    } else {
        self.topNMostParkingLoc = rawRegions;
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (0 == section) {
        return MIN(self.userFavLocs.count + 1, kMaxUserFavLocCnt);
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
        if (indexPath.row < self.userFavLocs.count) {
            DriveSuggestCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"suggestUsefulCell" forIndexPath:indexPath];
            [realCell updateWithFavLoc:self.userFavLocs[indexPath.row]];
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
            return CGSizeMake(320, 0);
            //return CGSizeMake(320, 40);
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
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (nil == curLoc) {
        [self showToast:@"当前gps不可用"];
        return;
    }
    if (0 == indexPath.section) {
        if (indexPath.row < self.userFavLocs.count) {
            CTFavLocation * locFav = self.userFavLocs[indexPath.row];
            ParkingRegionDetail * startDetail = [[AnaDbManager deviceDb] parkingDetailForCoordinate:curLoc.coordinate minDist:500];
            ParkingRegion * endRegion = [[AnaDbManager deviceDb] parkingRegioinForId:locFav.parking_id];
            
            CTRoute * route = [CTRoute new];
            [route updateWithDestCoor:locFav.coordinate andDestName:locFav.name fromCurrentLocation:curLoc];
            
            SuggestDetailViewController * suggestDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestDetailID"];
            suggestDetail.route = route;
            if (endRegion) {
                TripSummary * bestSum = [[AnaDbManager sharedInst] bestTripWithStartRegion:startDetail.coreDataItem endRegion:endRegion];
                suggestDetail.waypts = [bestSum wayPoints];
            }
            [self.navigationController pushViewController:suggestDetail animated:YES];
        } else {
            //[self showToast:@"自定义添加功能尚在开发中"];
            // 这里暂时把top most parking loc 加进来，作为测试
            NSInteger addIdx = self.userFavLocs.count;
            if (addIdx < self.topNMostParkingLoc.count) {
                ParkingRegionDetail * detail = self.topNMostParkingLoc[addIdx];
                CTFavLocation * favLoc = [detail.coreDataItem toFavLocation];
                [self.userFavLocs addObject:favLoc];
                [[BussinessDataProvider sharedInstance] putFavLocations:self.userFavLocs];
                
                [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            }
            
        }
    } else if (1 == indexPath.section) {
        if (indexPath.row > 0) {
            if (0 == _selCategoryIdx) {
                ParkingRegionDetail * selectRegion = self.topNMostParkingLoc[indexPath.row-1];
                ParkingRegionDetail * startDetail = [[AnaDbManager deviceDb] parkingDetailForCoordinate:curLoc.coordinate minDist:500];
                TripSummary * bestSum = [[AnaDbManager sharedInst] bestTripWithStartRegion:startDetail.coreDataItem endRegion:selectRegion.coreDataItem];

                CTRoute * route = [CTRoute new];
                [route updateWithDestRegion:selectRegion.coreDataItem fromCurrentLocation:curLoc];
                
                SuggestDetailViewController * suggestDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestDetailID"];
                suggestDetail.route = route;
                suggestDetail.waypts = [bestSum wayPoints];
                [self.navigationController pushViewController:suggestDetail animated:YES];
            } else {
                
            }

        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView rzTableLayout:(RZCollectionTableViewLayout *)layout editingButtonPressedForIndex:(NSUInteger)buttonIndex forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.row < self.userFavLocs.count) {
        [self.userFavLocs removeObjectAtIndex:indexPath.row];
    }
    [[BussinessDataProvider sharedInstance] putFavLocations:self.userFavLocs];
    [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
}

@end
