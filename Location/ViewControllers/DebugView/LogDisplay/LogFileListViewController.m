//
//  LogFileListViewController.m
//  Location
//
//  Created by taq on 9/22/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "LogFileListViewController.h"
#import "LogFileContentViewController.h"
#import "GPSLogger.h"

@interface LogFileListViewController ()

@property (nonatomic, strong) NSArray *         logFiles;

@end

@implementation LogFileListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Log File List";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadData];
}

- (void)reloadData
{
    NSMutableArray * fileNames = [NSMutableArray array];
    NSArray * fileArr = [[GPSLogger sharedLogger].fileLogger.logFileManager unsortedLogFileInfos];
    for (DDLogFileInfo * info in fileArr) {
        [fileNames addObject:info.filePath];
    }
    self.logFiles = fileNames;
    
    [self.fileListTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSIndexPath *indexPath = [self.fileListTable indexPathForSelectedRow];
    
    LogFileContentViewController* vc = (LogFileContentViewController *)[segue destinationViewController];
    vc.logFile = self.logFiles[indexPath.row];
}



#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.logFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"LogFileNameCellId" forIndexPath:indexPath];
    UILabel * contentLabel = (UILabel*)[cell.contentView viewWithTag:1000];
    
    NSString * fullFileName = [self.logFiles[indexPath.row] lastPathComponent];
    NSRange range = [fullFileName rangeOfString:@" "];
    contentLabel.text = [fullFileName substringFromIndex:range.location+range.length];
    
    return cell;
}

- (IBAction)clearAll:(id)sender
{
    NSArray * fileArr = [[GPSLogger sharedLogger].fileLogger.logFileManager sortedLogFilePaths];
    for (int i = 1; i < fileArr.count; i++) {
        [[NSFileManager defaultManager] removeItemAtPath:fileArr[i] error:nil];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}

@end
