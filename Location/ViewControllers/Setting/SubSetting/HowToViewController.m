//
//  HowToViewController.m
//  TripMan
//
//  Created by taq on 5/18/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "HowToViewController.h"
#import "HowToCell.h"

@interface HowToViewController ()

@property (nonatomic, strong) NSArray *             howToList;
@property (strong, nonatomic) AMBTableViewSection * howToSection;

@end

@implementation HowToViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView = self.howToTable;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
    self.tableView.tableFooterView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    
    self.title = @"用户指南";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.howToList = @[@[@"1、如何开启“定位服务”",@""],
                     @[@"2、如何添加、删除常用地点", @"添加常用地点：依次点击“出门问路” --> “添加常用地点” --> 选择目标地点。\r删除常用地点：进入“出门问路”页，向左滑动常用地点条，点击删除图标按钮即可删除地点。\r常用地点最多可以添加三处。"],
                     @[@"3、如何删除我的车票旅程", @"点击车票进入车票详情页，向下滑动到底部，点击删除这张车票按钮即可删除。"],
                     @[@"4、如何查看路况", @"您可以出门问路直接点击目标地点，也可以通过搜索找到您感兴趣的地点，进入实时路况页面，数据详情页面和题图轨迹页面可查看实时交通数据。"],
                     @[@"5、如何在地图上显示我的车票轨迹", @"找到您感兴趣的车票，点击车票进入车票详情页，第一页有一个速度分布球，点击这个球即可进入轨迹地图页面。"],
                     @[@"6、如何查看历史记录", @"进入“行车数据”页面，在屏幕的上半部分，左右滑动屏幕即可查看其他天，周，月的统计数据。"],
                     @[@"7、如何查看指定日期历史记录", @"在“行车数据”页面，点击日期标签可以快速回到当前日期，再次点击“今天”按钮，就会弹出日期筛选器，选择需要查看的日期，再点完成即可。"]];

    self.sections = @[self.howToSection];
}

- (AMBTableViewSection *)howToSection
{
    if (!_howToSection)
    {
        NSMutableIndexSet * initHideSet = [NSMutableIndexSet indexSet];
        NSMutableArray * sectionObjects = [NSMutableArray arrayWithCapacity:self.howToList.count*2];
        [self.howToList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [sectionObjects addObject:@(idx*2)];
            [sectionObjects addObject:@(idx*2+1)];
            [initHideSet addIndex:idx*2+1];
        }];
        _howToSection = [AMBTableViewSection
                       sectionWithObjects:sectionObjects
                       sectionUpdateBlock:^(AMBTableViewSection *section)
                       {
                           [section reload];
                       }
                       cellHeightBlock:^CGFloat(id object, NSIndexPath * indexPath)
                       {
                           NSInteger idx = [object integerValue];
                           if (1 == idx) {
                               return 0;
                           } else if (idx%2 == 0) {
                               return 44;
                           }
                           NSInteger realIdx = idx/2;
                           NSArray * realData = self.howToList[realIdx];
                           return [HowToDetailCell heightForCellWithContent:realData[1]];
                       }
                       cellIdentifierBlock:^NSString *(id object, NSIndexPath * indexPath)
                       {
                           NSInteger idx = [object integerValue];
                           return (idx%2 == 0) ? @"HowToCell" : @"HowToDetailCell";
                       }
                       cellConfigurationBlock:^(id object, UITableViewCell * cell, NSIndexPath * indexPath)
                       {
                           NSInteger idx = [object integerValue];
                           NSInteger realIdx = idx/2;
                           NSArray * realData = self.howToList[realIdx];
                           
                           if ([cell isKindOfClass:[HowToCell class]]) {
                               HowToCell * realCell = (HowToCell *)cell;
                               realCell.mainTitleLabel.text = realData[0];
                           } else if ([cell isKindOfClass:[HowToDetailCell class]]) {
                               HowToDetailCell * realCell = (HowToDetailCell *)cell;
                               realCell.mutableHeightLabel.text = realData[1];
                           }
                       }];
        
        // Initial state
        [_howToSection setObjectsAtIndexes:initHideSet hidden:YES];
    }
    return _howToSection;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AMBTableViewSection * section = self.sections[indexPath.section];
    NSInteger idx = [section.visibleObjects[indexPath.row] integerValue];
    
    [tableView deselectRowAtIndexPath:indexPath animated:(idx%2 == 0)];
    
    if (0 == idx) {
        UIViewController * openGpsVC = InstFirstVC(@"OpenGps");
        [self presentViewController:openGpsVC animated:YES completion:nil];
    } else if (idx%2 == 0) {
        NSInteger subIdx = idx+1;
        [section setObjectAtIndex:subIdx hidden:![section isObjectAtIndexHidden:subIdx]];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
