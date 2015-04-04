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

- (IBAction)reInstall:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://fir.im/y764"]];
}

- (void) clickBtn:(UIButton*)btn
{
    if (btn.tag == 12) {
        [self presentViewController:InstFirstVC(@"Debug") animated:YES completion:nil];
    } else {
        [self showToast:@"改功能尚在开发中..." onDismiss:nil];
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CarSettingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CarSettingCellId" forIndexPath:indexPath];
    
    if (indexPath.row == 0)
    {
        cell.shadowImage.hidden = YES;
        cell.backgroundColorView.backgroundColor = [UIColor clearColor];
        [cell.btn1 setBackgroundImage:[UIImage imageNamed:@"mycar_profile"] forState:UIControlStateNormal];
        [cell.btn2 setBackgroundImage:[UIImage imageNamed:@"mycar_setting"] forState:UIControlStateNormal];
        [cell.btn3 setBackgroundImage:[UIImage imageNamed:@"mycar_drivehabit"] forState:UIControlStateNormal];
        [cell.btn4 setBackgroundImage:[UIImage imageNamed:@"mycar_myshare"] forState:UIControlStateNormal];
        
        cell.btn1.tag = 11;
        [cell.btn1 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn2.tag = 12;
        [cell.btn2 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn3.tag = 21;
        [cell.btn3 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn4.tag = 22;
        [cell.btn4 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    else if (indexPath.row == 1)
    {
        cell.shadowImage.hidden = NO;
        cell.backgroundColorView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        [cell.btn1 setBackgroundImage:[UIImage imageNamed:@"mycar_obd"] forState:UIControlStateNormal];
        [cell.btn2 setBackgroundImage:[UIImage imageNamed:@"mycar_fine"] forState:UIControlStateNormal];
        [cell.btn3 setBackgroundImage:[UIImage imageNamed:@"mycar_driverecord"] forState:UIControlStateNormal];
        [cell.btn4 setBackgroundImage:[UIImage imageNamed:@"mycar_serveticket"] forState:UIControlStateNormal];
        
        cell.btn1.tag = 31;
        [cell.btn1 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn2.tag = 32;
        [cell.btn2 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn3.tag = 41;
        [cell.btn3 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        cell.btn4.tag = 42;
        [cell.btn4 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(320, 221);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(48.f, 0, 0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{

}

@end
