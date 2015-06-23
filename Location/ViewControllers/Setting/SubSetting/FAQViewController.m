//
//  FAQViewController.m
//  TripMan
//
//  Created by taq on 4/23/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "FAQViewController.h"
#import "FAQCell.h"

@interface FAQViewController ()

@property (nonatomic, strong) NSArray *             faqList;
@property (strong, nonatomic) AMBTableViewSection * faqSection;

@end

@implementation FAQViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView = self.faqTableView;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
    self.tableView.tableFooterView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1f];
    
    self.title = @"常见问题";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.faqList = @[@[@"1、如何打开行车记录功能", @"你只需安装并打开车图APP，开启“定位服务”，“车图”将智能判断你是否开车帮你记录你的行车状况，无需你做任何操作。"],
                     @[@"2、我的数据保存在哪里", @"我们将在本地和云服务上帮你存储你的历史记录，即便及删除或者丢失手机将来依然可以找回历史数据。"],
                     @[@"3、我的信息安全么", @"“车图”仅涉及道路信息，不会对您的私人信息进行收集，我们采用严格的数据存储和加密技术，为您的个人隐私提供最高级别保护。"],
                     @[@"4、APP会耗多少电量", @"以每日开车1小时计算，目前我们的电量消耗在3%以下，我们仍然在不断优化。如果您的手机存在电量消耗异常情况，请在意见反馈中联络反馈给我们。"],
                     @[@"5、APP分享会耗费很多流量么", @"数据保存和分享仅会在Wifi条件下才会进行，不会额外消耗流量，而实时路况和位置分享仅会在有路况情况下分享，每此分享流量不会超过1KB。"],
                     @[@"6、首页显示的是地点是怎么来的", @"首页会根据您的行驶习惯和行驶时间来判断您可能将要出发的地点位置，随着收录地点和时间越来越多，该判断将会越来越精准。"],
                     @[@"7、问路地图上的图钉代表什么含义", @"每个图钉都表示当前有用户最近正堵在地图上某个位置，不同的表情表示拥堵严重程度。"],
                     @[@"8、预计到达时间怎么来的", @"“车图”根据您的历史行程和交通大数据，通过时间，地点匹配温和方式进行综合评估计算，得出非异常情况下预计到达时间。"],
                     @[@"9、车票颜色代表什么", @"红色代表有严重拥堵路段，黄色代表拥有缓行路段，绿色代表道路通畅。"]];
    
    self.sections = @[self.faqSection];
    
}

- (AMBTableViewSection *)faqSection
{
    if (!_faqSection)
    {
        NSMutableIndexSet * initHideSet = [NSMutableIndexSet indexSet];
        NSMutableArray * sectionObjects = [NSMutableArray arrayWithCapacity:self.faqList.count*2];
        [self.faqList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [sectionObjects addObject:@(idx*2)];
            [sectionObjects addObject:@(idx*2+1)];
            [initHideSet addIndex:idx*2+1];
        }];
        _faqSection = [AMBTableViewSection
                       sectionWithObjects:sectionObjects
                       sectionUpdateBlock:^(AMBTableViewSection *section)
                       {
                           [section reload];
                       }
                       cellHeightBlock:^CGFloat(id object, NSIndexPath * indexPath)
                       {
                           NSInteger idx = [object integerValue];
                           if (idx%2 == 0) {
                               return 44;
                           }
                           NSInteger realIdx = idx/2;
                           NSArray * realData = self.faqList[realIdx];
                           return [FAQDetailCell heightForCellWithContent:realData[1]];
                       }
                       cellIdentifierBlock:^NSString *(id object, NSIndexPath * indexPath)
                       {
                           NSInteger idx = [object integerValue];
                           return (idx%2 == 0) ? @"FAQCell" : @"FAQDetailCell";
                       }
                       cellConfigurationBlock:^(id object, UITableViewCell * cell, NSIndexPath * indexPath)
                       {
                           NSInteger idx = [object integerValue];
                           NSInteger realIdx = idx/2;
                           NSArray * realData = self.faqList[realIdx];
                           
                           if ([cell isKindOfClass:[FAQCell class]]) {
                               FAQCell * realCell = (FAQCell *)cell;
                               realCell.mainTitleLabel.text = realData[0];
                           } else if ([cell isKindOfClass:[FAQDetailCell class]]) {
                               FAQDetailCell * realCell = (FAQDetailCell *)cell;
                               realCell.mutableHeightLabel.text = realData[1];
                           }
                       }];
        
        // Initial state
        [_faqSection setObjectsAtIndexes:initHideSet hidden:YES];
    }
    return _faqSection;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AMBTableViewSection * section = self.sections[indexPath.section];
    NSInteger idx = [section.visibleObjects[indexPath.row] integerValue];

    [tableView deselectRowAtIndexPath:indexPath animated:(idx%2 == 0)];
    
    if (idx%2 == 0) {
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
