//
//  CarMaintainInfoViewController.m
//  TripMan
//
//  Created by taq on 5/1/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "CarMaintainInfoViewController.h"
#import "CarMaintainCell.h"
#import "NSDate+Utilities.h"

typedef NS_ENUM(NSUInteger, eMaintainCellType) {
    eMaintainCellTypeTolDist,
    eMaintainCellTypeMaintainDist,
    eMaintainCellTypePeroid,
    eMaintainCellTypeConfirm,
    eMaintainCellTypeTolCnt,
};

@interface CarMaintainInfoViewController () {
    
    NSInteger         _newTolDist;
    NSInteger         _newLastMaintainDist;
    NSInteger         _newMaintainPeroid;
    
}

@property (nonatomic) BOOL                          showMaintainBtn;

@end

@implementation CarMaintainInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"添加保养信息";
    
    if (nil == self.maintainInfo) {
        self.maintainInfo = [[CarMaintainInfo alloc] init];
        [self.maintainInfo load];
    }
    
    if (self.maintainInfo.userTotalDist && self.maintainInfo.userLastMaintainDist &&
        [self.maintainInfo.userTotalDist integerValue] > [self.maintainInfo.userLastMaintainDist integerValue]) {
        self.showMaintainBtn = YES;
    }
    _newTolDist = self.maintainInfo.userTotalDist ? [self.maintainInfo totalDist] : -1;
    _newLastMaintainDist = self.maintainInfo.userLastMaintainDist ? [self.maintainInfo.userLastMaintainDist integerValue] : -1;
    _newMaintainPeroid = [self.maintainInfo.thresMaintainDist integerValue];
    
    self.saveBtn.enabled = [self hasModified];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.collectView addGestureRecognizer:gestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)hideKeyboard {
    [self.collectView endEditing:YES];
    self.saveBtn.enabled = [self hasModified];
}

- (BOOL)hasModified
{
    if (self.maintainInfo) {
        if (_newTolDist >= 0 && _newLastMaintainDist >= 0 && _newMaintainPeroid > 0) {
            if (nil == self.maintainInfo.userTotalDist || [self.maintainInfo totalDist] != _newTolDist) {
                return YES;
            }
            if (nil == self.maintainInfo.userLastMaintainDist || [self.maintainInfo.userLastMaintainDist integerValue] != _newLastMaintainDist) {
                return YES;
            }
            if ([self.maintainInfo.thresMaintainDist integerValue] != _newMaintainPeroid) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)textFieldDidChange:(UITextField*)textField
{
    if (eMaintainCellTypeTolDist == textField.tag) {
        _newTolDist = textField.text.length > 0 ? [textField.text integerValue] : -1;
    } else if (eMaintainCellTypeMaintainDist == textField.tag) {
        _newLastMaintainDist = textField.text.length > 0 ? [textField.text integerValue] : -1;
    } else if (eMaintainCellTypePeroid == textField.tag) {
        _newMaintainPeroid = textField.text.length > 0 ? [textField.text integerValue] : -1;
    }
    
    self.saveBtn.enabled = [self hasModified];
}

- (void)hasMaintainedRecently
{
    _newLastMaintainDist = _newTolDist;
    [self saveInfo:nil];
    
    self.showMaintainBtn = NO;
    
    [self.collectView reloadData];
}

- (IBAction)saveInfo:(id)sender
{
    [self.collectView endEditing:YES];
    
    if (_newTolDist < _newLastMaintainDist) {
        [self showToast:@"数据有误，上次保养里程大于总里程" onDismiss:nil];
        return;
    }
    self.maintainInfo.userTotalDist = @(_newTolDist);
    self.maintainInfo.userLastMaintainDist = @(_newLastMaintainDist);
    self.maintainInfo.thresMaintainDist = @(_newMaintainPeroid);
    self.maintainInfo.userUpdateDate = [NSDate date];
    [self.maintainInfo save];
    
    [self showToast:@"设置成功" onDismiss:nil];
    self.saveBtn.enabled = NO;
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView* reusableView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MaintainHeaderId" forIndexPath:indexPath];
    }
    
    return reusableView;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.showMaintainBtn) {
        return eMaintainCellTypeTolCnt;
    }
    return eMaintainCellTypeTolCnt-1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (eMaintainCellTypeTolDist == indexPath.row) {
        CarMaintainCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CarMaintainCellId" forIndexPath:indexPath];
        realCell.maintainTitle.text = @"当前里程";
        realCell.maintainContent.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"您爱车当前的里程数" attributes:@{ NSForegroundColorAttributeName : COLOR_UNIT_GRAY}];
        if (_newTolDist >= 0) {
            realCell.maintainContent.text = [NSString stringWithFormat:@"%ld", _newTolDist];
        } else {
            realCell.maintainContent.text = nil;
        }
        realCell.maintainContent.tag = indexPath.row;
        [realCell.maintainContent addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        cell = realCell;
    } else if (eMaintainCellTypeMaintainDist == indexPath.row) {
        CarMaintainCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CarMaintainCellId" forIndexPath:indexPath];
        realCell.maintainTitle.text = @"上次保养里程";
        realCell.maintainContent.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"爱车上次保养时的里程数" attributes:@{ NSForegroundColorAttributeName : COLOR_UNIT_GRAY}];
        if (_newLastMaintainDist >= 0) {
            realCell.maintainContent.text = [NSString stringWithFormat:@"%ld", _newLastMaintainDist];
        } else {
            realCell.maintainContent.text = nil;
        }
        realCell.maintainContent.tag = indexPath.row;
        [realCell.maintainContent addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        cell = realCell;
    } else if (eMaintainCellTypePeroid == indexPath.row) {
        CarMaintainCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CarMaintainCellId" forIndexPath:indexPath];
        realCell.maintainTitle.text = @"保养周期";
        realCell.maintainContent.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"您爱车的保养周期" attributes:@{ NSForegroundColorAttributeName : COLOR_UNIT_GRAY}];
        realCell.maintainContent.text = [self.maintainInfo.thresMaintainDist stringValue];
        realCell.maintainContent.tag = indexPath.row;
        [realCell.maintainContent addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        cell = realCell;
    } else if (eMaintainCellTypeConfirm == indexPath.row) {
        CarMaintainConfirmCell * realCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CarMaintainConfirmCellId" forIndexPath:indexPath];
        [realCell.maintainBtn addTarget:self action:@selector(hasMaintainedRecently) forControlEvents:UIControlEventTouchUpInside];
        cell = realCell;
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < eMaintainCellTypeConfirm) {
        return CGSizeMake(320.f, 48.f);
    } else if (indexPath.row == eMaintainCellTypeConfirm) {
        return CGSizeMake(320.f, 52.f);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.0f;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{

}

@end
