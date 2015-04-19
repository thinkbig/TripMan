//
//  SearchResultViewController.m
//  TripMan
//
//  Created by taq on 4/3/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "SearchResultViewController.h"
#import "SearchResultCell.h"
#import "SuggestDetailViewController.h"
#import "GeoTransformer.h"

@interface SearchResultViewController ()

@end

@implementation SearchResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.keyWord) {
        self.title = self.keyWord;
    } else {
        self.title = @"搜索结果";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.poiArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BMKPoiInfo * info = self.poiArray[indexPath.row];
    SearchResultCell * cell = [tableView dequeueReusableCellWithIdentifier:@"SearchResultCellId"];
    cell.poiLabel.text = info.name;
    cell.poiAddressLabel.text = info.address;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
 
    CLLocation * curLoc = [BussinessDataProvider lastGoodLocation];
    if (nil == curLoc) {
        [self showToast:@"当前gps不可用" onDismiss:nil];
        return;
    }
    BMKPoiInfo * info = self.poiArray[indexPath.row];
    
    CTRoute * route = [CTRoute new];
    [route setCoorType:eCoorTypeBaidu];
    
    route.orig = [CTBaseLocation new];
    route.orig.name = @"当前位置";
    [route.orig updateWithCoordinate:[GeoTransformer earth2Baidu:curLoc.coordinate]];
    
    route.dest = [CTBaseLocation new];
    route.dest.name = info.name ? info.name : @"目的地";
    [route.dest updateWithCoordinate:info.pt];
    
    SuggestDetailViewController * suggestDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestDetailID"];
    suggestDetail.route = route;
    [self.navigationController pushViewController:suggestDetail animated:YES];
}

@end
