//
//  SuggestOverLayerCollectionViewController.m
//  TripMan
//
//  Created by taq on 11/20/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "SuggestOverLayerCollectionViewController.h"
#import "SuggestDetailCell.h"
#import "ParkingRegion+Helper.h"

@interface SuggestOverLayerCollectionViewController ()

@end

@implementation SuggestOverLayerCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    // Do any additional setup after loading the view.
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

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (0 == section) {
        return 3+1;
    } else {
        return 6;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (0 == indexPath.section)
    {
        if (3 == indexPath.row) {
            UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JamCellExpendId" forIndexPath:indexPath];
            cell = realCell;
        } else {
            UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JamCellId" forIndexPath:indexPath];
            
            cell = realCell;
        }
    }
    else
    {
        if (0 == indexPath.row) {
            UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestFirstCell" forIndexPath:indexPath];
            
            cell = realCell;
        } else {
            UICollectionViewCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuggestListCell" forIndexPath:indexPath];
            
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
        header.destLabel.text = [self.tripSum.region_group.end_region prettyPOINameWithDefault:@"未知地点"];
        header.totalDistLabel.text = [NSString stringWithFormat:@"%.1f",[self.tripSum.total_dist floatValue]/1000.0];
        header.estimateDuringLabel.text = [NSString stringWithFormat:@"%.f",[self.tripSum.total_during floatValue]/60.0];
        NSDateFormatter * formatter = [[BussinessDataProvider sharedInstance] dateFormatterForFormatStr:@"HH:mm"];
        header.endDateLabel.text = [formatter stringFromDate:self.tripSum.end_date];
        reusableView = header;
    } else if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView* footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"SuggestFooter" forIndexPath:indexPath];
        reusableView = footer;
    }
    
    return reusableView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.section) {
        if (3 == indexPath.row) {
            return CGSizeMake(320.f, 30.f);
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
