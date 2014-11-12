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

- (IBAction)logSwitch:(id)sender {
    UINavigationItem * item = sender;
    if (self.autoAppend) {
        item.title = @"Auto";
    } else {
        item.title = @"Stop";
    }
    self.autoAppend = !_autoAppend;
}

@end
