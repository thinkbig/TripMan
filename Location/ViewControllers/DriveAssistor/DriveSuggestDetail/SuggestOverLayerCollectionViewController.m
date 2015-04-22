//
//  SuggestOverLayerCollectionViewController.m
//  TripMan
//
//  Created by taq on 11/20/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "SuggestOverLayerCollectionViewController.h"
#import "SuggestDetailCell.h"
#import "ParkingRegion+Fetcher.h"
#import "NSArray+ObjectiveSugar.h"

#define kMaxJamDisplayCount         3

@interface SuggestOverLayerCollectionViewController ()

@property (nonatomic) BOOL  expand;
@property (nonatomic, strong) NSArray * allJams;

@end

@implementation SuggestOverLayerCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.scrollEnabled = NO;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setRoute:(CTRoute *)route
{
    _route = route;
    
    NSMutableArray * jamInfo = [NSMutableArray array];
    for (CTStep * step in route.steps) {
        NSArray * filteredJamArr = [step jamsWithThreshold:cTrafficJamThreshold];
        if (filteredJamArr.count > 0) {
            [jamInfo addObjectsFromArray:filteredJamArr];
        }
    }
    self.allJams = jamInfo;
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
    return 2;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (0 == section) {
        if (self.allJams.count == 0) {
            return 0;
        } else if (self.allJams.count > kMaxJamDisplayCount) {
            return self.expand ? self.allJams.count : kMaxJamDisplayCount+1;
        } else {
            return self.allJams.count;
        }
    } else {
        return self.predictDict ? self.predictDict.count + 1 : 6;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (0 == indexPath.section)
    {
        if (!self.expand) {
            if (kMaxJamDisplayCount == indexPath.row) {
                UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JamCellExpendId" forIndexPath:indexPath];
                cell = realCell;
            }
        }
        if (nil == cell) {
            SuggestDetailCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestDetailCellId" forIndexPath:indexPath];
            CTJam * jam = nil;
            if (indexPath.row < self.allJams.count) {
                jam = self.allJams[indexPath.row];
            }
            [realCell updateWithJam:jam];
            
            cell = realCell;
        }
    }
    else
    {
        if (0 == indexPath.row) {
            UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestFirstCell" forIndexPath:indexPath];
            
            cell = realCell;
        } else {
            SuggestPredictCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestPredictCellId" forIndexPath:indexPath];
            NSArray * allKeys = [[self.predictDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [@([obj1 integerValue]) compare:@([obj2 integerValue])];
            }];
            if (indexPath.row-1 < allKeys.count) {
                NSString * curMin = allKeys[indexPath.row-1];
                CGFloat coef = [self.predictDict[curMin] floatValue];
                CGFloat duration = [self.route.duration floatValue];
                [realCell updateWithStartTime:[NSDate dateWithTimeIntervalSinceNow:[curMin integerValue]*60] andDuration:duration*coef];
            } else {
                [realCell updateWithStartTime:nil andDuration:0];
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
        SuggestDetailHeader* header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SuggestHeader" forIndexPath:indexPath];
        if (nil == self.route && self.tripSum) {
            [header updateWithTrip:self.tripSum];
        } else {
            [header updateWithRoute:self.route];
        }
        reusableView = header;
    } else if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView* footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"SuggestFooter" forIndexPath:indexPath];
        reusableView = footer;
    }
    
    return reusableView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.section) {
        if (!self.expand) {
            if (kMaxJamDisplayCount == indexPath.row) {
                return CGSizeMake(320.f, 30.f);
            }
        }
        return CGSizeMake(320.f, 70.f);
    } else if (1 == indexPath.section) {
        if (0 == indexPath.row) {
            return CGSizeMake(320, 35);
        } else {
            return CGSizeMake(320, 55);
        }
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0.f, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
{
    if (0 == section) {
        return CGSizeMake(320, 114);
    }
    return CGSizeZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.expand) {
        if (kMaxJamDisplayCount == indexPath.row) {
            self.expand = YES;
            [collectionView reloadData];
        }
    }
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
