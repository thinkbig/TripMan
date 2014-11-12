//
//  BackgroundTaskManager.m
//
//  Created by Puru Shukla on 20/02/13.
//  Copyright (c) 2013 Puru Shukla. All rights reserved.
//

#import "BackgroundTaskManager.h"

@interface BgTask : NSObject

@property (nonatomic) UIBackgroundTaskIdentifier    taskId;

- (UIBackgroundTaskIdentifier) beginBackgroundTask;
- (void) endTask;

@end

@implementation BgTask

- (UIBackgroundTaskIdentifier) beginBackgroundTask
{
    self.taskId = UIBackgroundTaskInvalid;
    if([[UIApplication sharedApplication] respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]){
        self.taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            DDLogWarn(@"expired background task: %lu", (unsigned long)self.taskId);
            self.taskId = UIBackgroundTaskInvalid;
        }];
    }
    return self.taskId;
}

- (void) endTask
{
    [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
    self.taskId = UIBackgroundTaskInvalid;
}

@end



////////////////////////////////////////////////////////////////////////////////////////

@interface BackgroundTaskManager()
@property (nonatomic, strong)NSMutableArray* bgTaskList;
//@property (assign) UIBackgroundTaskIdentifier masterTaskId;
@end

@implementation BackgroundTaskManager

+(instancetype)sharedBackgroundTaskManager{
    static BackgroundTaskManager* sharedBGTaskManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBGTaskManager = [[BackgroundTaskManager alloc] init];
    });
    
    return sharedBGTaskManager;
}

-(id)init{
    self = [super init];
    if(self){
        _bgTaskList = [NSMutableArray array];
        //_masterTaskId = UIBackgroundTaskInvalid;
    }
    
    return self;
}

-(void)beginNewBackgroundTask
{
    BgTask * task = [BgTask new];
    UIBackgroundTaskIdentifier bgTaskId = [task beginBackgroundTask];
    if(bgTaskId != UIBackgroundTaskInvalid)
    {
        [self.bgTaskList addObject:task];
        [self endBackgroundTasks];
//        if ( self.masterTaskId == UIBackgroundTaskInvalid )
//        {
//            self.masterTaskId = bgTaskId;
//            NSLog(@"started master task %lu", (unsigned long)self.masterTaskId);
//        }
//        else
//        {
//            //add this id to our list
//            NSLog(@"started background task %lu", (unsigned long)bgTaskId);
//            [self.bgTaskIdList addObject:@(bgTaskId)];
//            [self endBackgroundTasks];
//        }
    }
}

-(void)endBackgroundTasks
{
    [self drainBGTaskList:NO];
}

-(void)endAllBackgroundTasks
{
    [self drainBGTaskList:YES];
}

-(void)drainBGTaskList:(BOOL)all
{
    //mark end of each of our background task
    UIApplication* application = [UIApplication sharedApplication];
    if([application respondsToSelector:@selector(endBackgroundTask:)]){
        NSUInteger count=self.bgTaskList.count;
        for ( NSUInteger i=(all?0:1); i<count; i++ )
        {
            BgTask * bgTask = self.bgTaskList[0];
            [bgTask endTask];
            [self.bgTaskList removeObjectAtIndex:0];
        }
        if ( self.bgTaskList.count > 0 )
        {
            NSLog(@"kept background task id %@", [self.bgTaskList objectAtIndex:0]);
        }
//        if ( all )
//        {
//            NSLog(@"no more background tasks running");
//            [application endBackgroundTask:self.masterTaskId];
//            self.masterTaskId = UIBackgroundTaskInvalid;
//        }
//        else
//        {
//            NSLog(@"kept master background task id %lu", (unsigned long)self.masterTaskId);
//        }
    }
}


@end
