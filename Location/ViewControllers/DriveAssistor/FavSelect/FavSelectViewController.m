//
//  FavSelectViewController.m
//  TripMan
//
//  Created by taq on 4/4/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "FavSelectViewController.h"
#import "FavSelectCell.h"
#import "ParkingRegion+Fetcher.h"

@interface FavSelectViewController ()

@property (nonatomic, strong) NSArray *         parkingRegions;
@property (nonatomic, strong) NSMutableArray *  userFavLocs;

@end

@implementation FavSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"添加关注";
    
    [self updateContent];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateContent
{
    NSArray * userParkings = [[AnaDbManager sharedInst] mostUsedParkingRegionLimit:0];
    NSMutableArray * tmpArr = [NSMutableArray array];
    for (ParkingRegionDetail * detail in userParkings) {
        if ([detail.coreDataItem.is_analyzed boolValue]) {
            [tmpArr addObject:detail];
        }
    }
    self.parkingRegions = tmpArr;
    
    NSArray * favLoc = [[BussinessDataProvider sharedInstance] favLocations];
    if (favLoc.count > 0) {
        self.userFavLocs = [NSMutableArray arrayWithArray:favLoc];
    } else {
        self.userFavLocs = [NSMutableArray array];
    }

    [self.favSelectTable reloadData];
}

- (CTFavLocation*) favorateLoc:(ParkingRegion*)region
{
    NSArray * tmpArr = [self.userFavLocs copy];
    for (CTFavLocation * favLoc in tmpArr) {
        if ([region.parking_id isEqualToString:favLoc.parking_id] ||
            ([favLoc.name isEqualToString:[region nameWithDefault:@""]] && [favLoc.street isEqualToString:region.street])) {
            return favLoc;
        }
    }
    return nil;
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
    return self.parkingRegions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ParkingRegionDetail * info = self.parkingRegions[indexPath.row];
    FavSelectCell * cell = [tableView dequeueReusableCellWithIdentifier:@"FavSelectCellId"];
    cell.poiName.text = [info.coreDataItem nameWithDefault:@"未知位置"];
    cell.poiAddress.text = info.coreDataItem.street;
    cell.accessoryType = (nil != [self favorateLoc:info.coreDataItem]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ParkingRegionDetail * info = self.parkingRegions[indexPath.row];
    CTFavLocation * fav = [self favorateLoc:info.coreDataItem];
    if (fav) {
        [self.userFavLocs removeObject:fav];
    } else if (self.userFavLocs.count >= kMaxUserFavLocCnt) {
        [self showToast:@"最多添加3个关注地点" onDismiss:nil];
        return;
    } else {
        fav = [CTFavLocation new];
        [fav updateWithParkingRegion:info.coreDataItem];
        [self.userFavLocs addObject:fav];
    }
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [[BussinessDataProvider sharedInstance] putFavLocations:self.userFavLocs];
}

@end
