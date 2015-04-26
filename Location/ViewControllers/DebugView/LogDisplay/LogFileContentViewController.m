//
//  LogFileContentViewController.m
//  Location
//
//  Created by taq on 9/22/14.
//  Copyright (c) 2014 Location. All rights reserved.
//

#import "LogFileContentViewController.h"

@interface LogFileContentViewController ()

@property (nonatomic, retain) NSFileHandle *        fileHandle;

@end

@implementation LogFileContentViewController

- (void)awakeFromNib
{
    self.autoAppend = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"LogContent";
    self.logConentView.delegate = self;
    
    [self fileNotify];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self.fileHandle closeFile];
}

- (void)fileNotify
{
    if (nil == self.fileHandle) {
        self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.logFile];
    }
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(getData:) name:@"NSFileHandleReadCompletionNotification" object:self.fileHandle];
	[self.fileHandle readInBackgroundAndNotify];
}

- (void)getData:(NSNotification *)notification {
	NSData *data = notification.userInfo[NSFileHandleNotificationDataItem];
	if (data.length) {
		NSString *string = [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
		self.logConentView.text = [self.logConentView.text stringByAppendingString:string];
	}
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        if (data.length) {
            [self scrollToLast];
        }
        [notification.object readInBackgroundAndNotify];
    });
}

- (void)scrollToLast
{
    if (self.autoAppend) {
        NSRange txtOutputRange;
        txtOutputRange.location = self.logConentView.text.length-1;
        txtOutputRange.length = 0;
        [self.logConentView scrollRangeToVisible:txtOutputRange];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)logSwitch:(id)sender
{
    if (![MFMailComposeViewController canSendMail]) {
        [self showToast:@"无法发送邮件，请确认正确设置了手机的邮件账号" onDismiss:nil];
        return;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.logFile])
    {
        MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc] init];
        mailCompose.mailComposeDelegate = self;
        
        NSArray *toAddress = [NSArray arrayWithObject:@"87149798@qq.com"];
        NSString *emailBody = [NSString stringWithFormat:@"<H1>日志信息</H1> <p>%@</p>", [[GToolUtil sharedInstance] deviceId]];
        
        [mailCompose setToRecipients:toAddress];
        [mailCompose setMessageBody:emailBody isHTML:YES];
        
        NSData* pData = [[NSData alloc]initWithContentsOfFile:self.logFile];
        
        [mailCompose setSubject:[NSString stringWithFormat:@"车图Log from: %@", [UIDevice currentDevice].name]];
        //设置邮件附件{mimeType:文件格式|fileName:文件名}
        NSString * fullFileName = [[self.logFile pathComponents] lastObject];
        NSRange range = [fullFileName rangeOfString:@" "];
        NSString * shortName = [fullFileName substringFromIndex:range.location+range.length];
        [mailCompose addAttachmentData:pData mimeType:@"txt" fileName:shortName];
        [self.navigationController presentViewController:mailCompose animated:YES completion:nil];
    }
}


#pragma mark - delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.autoAppend = NO;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *msg = @"邮件发送";
    switch (result)
    {
        case MFMailComposeResultCancelled:
            msg = @"邮件发送取消";
            break;
        case MFMailComposeResultSaved:
            msg = @"邮件保存成功";
            break;
        case MFMailComposeResultSent:
            msg = @"邮件发送成功";
            break;
        case MFMailComposeResultFailed:
            msg = @"邮件发送失败";
            break;
        default:
            break;
    }
    [self showToast:msg onDismiss:nil];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
