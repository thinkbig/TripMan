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
#import "SearchSuggestionCell.h"
#import "SearchClearCell.h"
#import "SearchHistoryCell.h"
#import "BaiduPOISearchWrapper.h"
#import "SearchResultViewController.h"
#import "NSString+ObjectiveSugar.h"
#import "FavSelectViewController.h"
#import "UIAlertView+RZCompletionBlocks.h"

@interface CarAssistorViewController () {
    ZBNSearchDisplayController *       searchDisplayController;
}

@property (nonatomic, strong) NSMutableArray *                  userFavLocs;
@property (nonatomic, strong) NSMutableArray *                  mostParkingLoc;
@property (nonatomic, strong) NSArray *                         bdPoiLoc;

@property (nonatomic, strong) SearchPOIHeader*                  header;
@property (nonatomic, strong) NSArray *                         categories;
@property (nonatomic) NSUInteger                                selCategoryIdx;

@property (nonatomic, strong) NSArray *                         localSuggestion;
@property (nonatomic, strong) NSMutableArray *                  recentSearch;
@property (nonatomic, strong) NSString *                        curCity;

@end

@implementation CarAssistorViewController

- (void)internalInit
{
    self.curCity = @"中国";
    self.categories = [[CTPOICategoryFacade new] defaultCategorys];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
    _searchBar.translucent = YES;
    _searchBar.placeholder = @"搜索要去的地名                            ";
    _searchBar.barTintColor = [UIColor clearColor];
    _searchBar.backgroundColor = [UIColor clearColor];
    [self.searchBar setSearchFieldBackgroundImage:[UIImage rz_solidColorImageWithSize:CGSizeMake(28, 28) color:[UIColor clearColor]] forState:UIControlStateNormal];
    [_searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    
    searchDisplayController = [[ZBNSearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    
    [searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"SearchSuggestionCell" bundle:nil] forCellReuseIdentifier:@"SearchSuggestCellId"];
    [searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"SearchClearCell" bundle:nil] forCellReuseIdentifier:@"SearchClearCellId"];
    [searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"SearchHistoryCell" bundle:nil] forCellReuseIdentifier:@"SearchHistoryCellId"];
    
    [_searchBar setImage:[UIImage new] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    _searchBar.searchTextPositionAdjustment = UIOffsetMake(8, 0);
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:UIColorFromRGB(0xaaaaaa)];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{
                                                                                                 NSFontAttributeName: [UIFont boldSystemFontOfSize:14],
                                                                                                 NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.2]
                                                                                                 }];
}

//- (void)updateData
//{
//    CTPOICategoryFacade * poiFacade = [CTPOICategoryFacade new];
//    [poiFacade requestWithSuccess:^(id array) {
//        self.categories = array;
//    } failure:nil];
//}

- (void)reloadContent
{
    NSArray * userFav = [[BussinessDataProvider sharedInstance] favLocations];
    if (userFav.count > 0) {
        self.userFavLocs = [NSMutableArray arrayWithArray:[userFav subarrayWithRange:NSMakeRange(0, MIN(kMaxUserFavLocCnt, userFav.count))]];
    } else {
        self.userFavLocs = [NSMutableArray array];
    }
    
    self.recentSearch = [NSMutableArray arrayWithArray:[[BussinessDataProvider sharedInstance] recentSearches]];
    
    NSArray * loadArr = [[BussinessDataProvider sharedInstance] bestGuessLocations:0 formatToDetail:YES thresDist:IGNORE_NAVIGATION_DIST];
    self.mostParkingLoc = [NSMutableArray arrayWithArray:loadArr];
    
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    [[BussinessDataProvider sharedInstance] updateCurrentCity:^(NSString * city) {
        if (city) {
            self.curCity = city;
            
            if (nil == self.bdPoiLoc && self.mostParkingLoc.count < kMostParkingShowCnt) {
                BaiduPOISearchWrapper * wrapper = [BaiduPOISearchWrapper new];
                wrapper.city = city;
                wrapper.searchName = @"商圈";
                [wrapper requestWithSuccess:^(BMKPoiResult * result) {
                    if (result.poiInfoList.count > 0) {
                        NSMutableArray * tmpArr = [NSMutableArray array];
                        for (BMKPoiInfo * oneInfo in result.poiInfoList) {
                            CLLocation * infoLoc = [[CLLocation alloc] initWithLatitude:oneInfo.pt.latitude longitude:oneInfo.pt.longitude];
                            CGFloat dist = [curLoc distanceFromLocation:infoLoc];
                            if (dist < 400 || dist > 20*1000) {
                                continue;
                            }
                            [tmpArr addObject:oneInfo];
                        }
                        self.bdPoiLoc = tmpArr;
                        [self.suggestCollectionView reloadData];
                    }
                } failure:^(NSError * err) {
                    NSLog(@"fail to get baidu poi info for 商圈");
                }];
            }
        }
    } forceUpdate:YES];
    
    
    [self.suggestCollectionView reloadData];
    [self updateSuggestionByKeyword:self.searchBar.text];
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
            return MIN(kMostParkingShowCnt, self.mostParkingLoc.count + self.bdPoiLoc.count) + 1;
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
            realCell._rz_parentCollectionTableView = self.suggestCollectionView;
            RZCollectionTableViewCellEditingItem * delItem = [RZCollectionTableViewCellEditingItem itemWithIcon:[UIImage imageNamed:@"deleteicon"] highlightedIcon:[UIImage imageNamed:@"deleteicon"] backgroundColor:[UIColor clearColor] hostBgImg:[UIImage imageNamed:@"deletetag"]];
            [realCell setRzEditingItems:@[delItem]];
            realCell.rzEditingEnabled = YES;
            if (0 == _selCategoryIdx) {
                NSInteger realIdx = indexPath.row-1;
                NSInteger parkingLocCnt = self.mostParkingLoc.count;
                if (realIdx < parkingLocCnt) {
                    [realCell updateWithLocation:self.mostParkingLoc[realIdx]];
                } else if (realIdx < parkingLocCnt + self.bdPoiLoc.count) {
                    [realCell updateWithBDPoiInfo:self.bdPoiLoc[realIdx-parkingLocCnt]];
                }
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
        [self showToast:@"当前gps不可用" onDismiss:nil];
        return;
    }
    if (0 == indexPath.section) {
        if (indexPath.row < self.userFavLocs.count) {
            CTFavLocation * locFav = self.userFavLocs[indexPath.row];
            CGFloat dist = [locFav distanceFromLoc:curLoc];
            if (dist < 800) {
                [self showToast:@"当前就在目标附近" onDismiss:nil];
            } else {
                CTRoute * route = [CTRoute new];
                [route setCoorType:eCoorTypeBaidu];
                route.orig.name = @"当前位置";
                [route.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
                route.dest.name = locFav.name ? locFav.name : @"目的地";
                [route.dest updateWithCoordinate:[GeoTransformer earth2Baidu:locFav.coordinate]];
                
                SuggestDetailViewController * suggestDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestDetailID"];
                suggestDetail.route = route;
                suggestDetail.endParkingId = locFav.parking_id;
                [self.navigationController pushViewController:suggestDetail animated:YES];
            }
        } else {
            if (0 == self.mostParkingLoc.count) {
                [self showToast:@"您还没有行驶记录\r尚未生成常用地点" onDismiss:nil];
            } else {
                FavSelectViewController * favSelVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FavSelectVC"];
                [self.navigationController pushViewController:favSelVC animated:YES];
            }
        }
    } else if (1 == indexPath.section) {
        if (indexPath.row > 0) {
            if (0 == _selCategoryIdx) {
                NSInteger realIdx = indexPath.row-1;
                NSInteger parkingLocCnt = self.mostParkingLoc.count;
                if (realIdx < parkingLocCnt) {
                    id selectRegion = self.mostParkingLoc[indexPath.row-1];
                    [self gotoDetail:selectRegion fromLoc:curLoc];
                } else if (realIdx < parkingLocCnt + self.bdPoiLoc.count) {
                    id selectInfo = self.bdPoiLoc[realIdx-parkingLocCnt];
                    [self gotoPoiInfo:selectInfo fromLoc:curLoc];
                }
            } else {
                
            }

        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView rzTableLayout:(RZCollectionTableViewLayout *)layout editingButtonPressedForIndex:(NSUInteger)buttonIndex forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (0 == indexPath.section) {
        if (indexPath.row < self.userFavLocs.count) {
            [self.userFavLocs removeObjectAtIndex:indexPath.row];
        }
        [[BussinessDataProvider sharedInstance] putFavLocations:self.userFavLocs];
        [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } else if (1 == indexPath.section) {
        NSInteger realIdx = indexPath.row-1;
        NSInteger parkingLocCnt = self.mostParkingLoc.count;
        if (realIdx < parkingLocCnt) {
            
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"是否删除？" message:@"删除后，即使将来再次开车到达该目的地，也不会出现在常用地点列表" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"删除", nil];
            [alert rz_showWithCompletionBlock:^(NSInteger dismissalButtonIndex) {
                if (1 == dismissalButtonIndex) {
                    ParkingRegionDetail * selectRegion = self.mostParkingLoc[indexPath.row-1];
                    selectRegion.coreDataItem.rate = @(-1);
                    [self.mostParkingLoc removeObject:selectRegion];
                    [[AnaDbManager sharedInst] commit];
                    [collectionView reloadSections:[NSIndexSet indexSetWithIndex:1]];
                }
            }];

        } else if (realIdx < parkingLocCnt + self.bdPoiLoc.count) {
            [self showToast:@"目前只支持删除您开车到过的位置" onDismiss:nil];
        }
    }
}


#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.localSuggestion.count == 0) {
        if (self.recentSearch.count > 0) {
            return self.recentSearch.count + 1;
        }
    }
    return self.localSuggestion.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;
    
    if (self.localSuggestion.count == 0) {
        if (self.recentSearch.count > 0) {
            if (indexPath.row < self.recentSearch.count) {
                SearchHistoryCell * realCell = [tableView dequeueReusableCellWithIdentifier:@"SearchHistoryCellId"];
                CTFavLocation * loc = self.recentSearch[indexPath.row];
                realCell.histLabel.text = loc.name;
                cell = realCell;
            } else {
                SearchClearCell * realCell = [tableView dequeueReusableCellWithIdentifier:@"SearchClearCellId"];
                cell = realCell;
            }
        }
    } else {
        ParkingRegionDetail * parking = self.localSuggestion[indexPath.row];
        SearchSuggestionCell * realCell = [tableView dequeueReusableCellWithIdentifier:@"SearchSuggestCellId"];
        realCell.destNameLabel.text = [parking.coreDataItem nameWithDefault:@"未知地点"];
        realCell.destStreetLabel.text = parking.coreDataItem.street;
        cell = realCell;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.localSuggestion.count == 0) {
        return 50;
    }
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.localSuggestion.count == 0) {
        if (indexPath.row < self.recentSearch.count) {
            CTFavLocation * loc = self.recentSearch[indexPath.row];
            [self searchWithKeyword:loc.name andCity:loc.city];
        } else if (indexPath.row == self.recentSearch.count) {
            [self.recentSearch removeAllObjects];
            [[BussinessDataProvider sharedInstance] putRecentSearches:nil];
            [tableView reloadData];
        }
    } else {
        CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
        if (nil == curLoc) {
            [self showToast:@"当前gps不可用" onDismiss:nil];
            return;
        }
        ParkingRegionDetail * selectRegion = self.localSuggestion[indexPath.row];
        [self gotoDetail:selectRegion fromLoc:curLoc];
    }
}

- (void) gotoDetail:(ParkingRegionDetail*)selectRegion fromLoc:(CLLocation*)curLoc
{    
    CTRoute * route = [CTRoute new];
    [route setCoorType:eCoorTypeBaidu];
    route.orig.name = @"当前位置";
    [route.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
    route.dest.name = [selectRegion.coreDataItem nameWithDefault:@"目的地"];
    [route.dest updateWithCoordinate:[GeoTransformer earth2Baidu:[selectRegion.coreDataItem centerCoordinate]]];
    
    SuggestDetailViewController * suggestDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestDetailID"];
    suggestDetail.route = route;
    suggestDetail.endParkingId = selectRegion.coreDataItem.parking_id;
    [self.navigationController pushViewController:suggestDetail animated:YES];
}

- (void) gotoPoiInfo:(BMKPoiInfo*)poiInfo fromLoc:(CLLocation*)curLoc
{
    CTRoute * route = [CTRoute new];
    [route setCoorType:eCoorTypeBaidu];
    route.orig.name = @"当前位置";
    [route.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
    route.dest.name = poiInfo.name;
    [route.dest updateWithCoordinate:poiInfo.pt];
    
    SuggestDetailViewController * suggestDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestDetailID"];
    suggestDetail.route = route;
    [self.navigationController pushViewController:suggestDetail animated:YES];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

#pragma mark - ZBNSearchDisplayDelegate

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    //self.header.rightIcon.hidden = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self enableControlsInView:self.searchBar];
    });
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.hidesBottomBarWhenPushed = NO;
    [ROOT_VIEW_CONTROLLER showTabBar:TSTabShowHideFromBottom animated:YES];
    [searchDisplayController updateLayout];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    //self.header.rightIcon.hidden = YES;
    self.hidesBottomBarWhenPushed = YES;
    [ROOT_VIEW_CONTROLLER hideTabBar:TSTabShowHideFromBottom animated:YES];
    [searchDisplayController updateLayout];
    
    [self updateSuggestionByKeyword:searchBar.text];
}

- (void)textDidChange:(NSString *)searchText
{
    [self updateSuggestionByKeyword:searchText];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString * proposedNewString = [[searchBar text] stringByReplacingCharactersInRange:range withString:text];
    [self updateSuggestionByKeyword:proposedNewString];
    return YES;
}

- (void)searchDisplayControllerDidBeginSearch:(ZBNSearchDisplayController *)controller
{
    NSString * searchKey = [controller.searchBar.text strip];
    if (searchKey.length == 0) {
        [self showToast:@"请输入搜索关键字" onDismiss:nil];
        return;
    }
    
    [self searchWithKeyword:searchKey andCity:self.curCity];
}


#pragma mark - Private

- (void) searchWithKeyword:(NSString*)key andCity:(NSString*)city
{
    // ios7 中如果没有这一句会有bug
    [self.searchBar endEditing:YES];

    [self showLoading];
    BaiduPOISearchWrapper * wrapper = [BaiduPOISearchWrapper new];
    wrapper.city = city;
    wrapper.searchName = key;
    [wrapper requestWithSuccess:^(BMKPoiResult * result) {
        [self hideLoading];
        if (result.poiInfoList.count > 0) {
            SearchResultViewController * resultVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchResultVC"];
            resultVC.poiArray = result.poiInfoList;
            self.searchBar.text = nil;
            [self.navigationController pushViewController:resultVC animated:YES];
        } else if (result.cityList.count > 0) {
            [self showToast:@"请尝试在关键字前面加上城市" onDismiss:nil];
        } else {
            [self showToast:@"无法搜到结果，请尝试其他关键字" onDismiss:nil];
        }
    } failure:^(NSError * err) {
        [self hideLoading];
        if ([err.domain isEqualToString:@"clientErrDomain"]) {
            NSString * msg = [GToolUtil msgWithErr:err andDefaultMsg:@"无法搜到结果，请尝试其他关键字"];
            [self showToast:msg onDismiss:nil];
        } else {
            [self showToast:@"搜索失败，请稍后再试" onDismiss:nil];
        }
    }];
    
    
    CTFavLocation * searchLoc = nil;
    for (CTFavLocation * loc in self.recentSearch) {
        if (([loc.name isEqualToString:key] || key == loc.name) &&
            ([loc.city isEqualToString:city] || city == loc.city)) {
            searchLoc = loc;
            break;
        }
    }
    if (nil == searchLoc) {
        searchLoc = [CTFavLocation new];
        searchLoc.name = key;
        searchLoc.city = city;
    } else {
        [self.recentSearch removeObject:searchLoc];
    }
    
    [self.recentSearch insertObject:searchLoc atIndex:0];
    [[BussinessDataProvider sharedInstance] putRecentSearches:self.recentSearch];
    
    [searchDisplayController.searchResultsTableView reloadData];
}

- (void) updateSuggestionByKeyword:(NSString*)keyword
{
    if (keyword.length == 0) {
        self.localSuggestion = nil;
    } else {
        NSMutableArray * tmpArr = [NSMutableArray arrayWithCapacity:self.mostParkingLoc.count];
        for (ParkingRegionDetail * detail in self.mostParkingLoc) {
            if ([detail matchString:keyword]) {
                [tmpArr addObject:detail];
            }
        }
        self.localSuggestion = tmpArr;
    }
    
    [searchDisplayController.searchResultsTableView reloadData];
}

- (void)enableControlsInView:(UIView *)view {
    for (id subview in view.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview setEnabled:YES];
        }
        [self enableControlsInView:subview];
    }
}

@end
