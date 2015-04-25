//
//  CarSettingViewController.m
//  Location
//
//  Created by taq on 10/31/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "CarSettingViewController.h"
#import "CarSettingCell.h"

@interface CarSettingViewController ()

@end

@implementation CarSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
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

- (void) clickBtn:(UIButton*)btn
{
    if (btn.tag == 11) {
        UIViewController * vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (btn.tag == 12) {
        UIViewController * vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FeedbackViewController"];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (btn.tag == 21) {
        UIViewController * vc = [self.storyboard instantiateViewControllerWithIdentifier:@"VersionInfoViewController"];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (btn.tag == 22) {
        UIViewController * vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FAQViewController"];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (btn.tag == 31) {
        [self showToast:@"产品还没有上线" onDismiss:nil];
    } else if (btn.tag == 32) {
        [self showToast:@"产品还没有上线" onDismiss:nil];
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CarSettingSixCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CarSettingSixCellId" forIndexPath:indexPath];
    
    if (indexPath.row == 0)
    {
        cell.shadowImage.hidden = YES;
        cell.backgroundColorView.backgroundColor = [UIColor clearColor];

        cell.btn1.tag = 11;
        [cell.btn1 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn2.tag = 12;
        [cell.btn2 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn3.tag = 21;
        [cell.btn3 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn4.tag = 22;
        [cell.btn4 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn5.tag = 31;
        [cell.btn5 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn6.tag = 32;
        [cell.btn6 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(320, 332);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake((self.view.bounds.size.height - 332)/2.0f, 0, 0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
