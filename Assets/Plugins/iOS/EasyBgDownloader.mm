//
//  EasyBgDownloader.m
//  
//
//  Created by Yuta Nakagawa on 2/16/16.
//
//

#import <Foundation/Foundation.h>
#import "EasyBgDownloader.h"
#import "EBDTaskManager.h"


@interface EasyBgDownloader () <NSURLSessionDelegate> {
    NSString *_currentRequestURL;
    NSURLSessionDownloadTask *_currentDownloadTask;
    float _currentProgress;
    EBDTaskManager *_taskManager;
    
    NSString *_prdName;
    NSString *_gameObjName;
    BOOL _cacheEnabled;
    
    //<NSString, NSNumber>
    NSMutableDictionary *_taskIdList;
    //<NSNumber, NSURLSessionDownloadTask>
    NSMutableDictionary *_taskList;
    //<NSNumber, NSString>
    NSMutableDictionary *_destPathList;
}
typedef NS_ENUM (int, EBDUnityStatus) {
    UnityStatusNotInQueue = -100,
    UnityStatusPending = 10,
    UnityStatusRunning = 20,
    UnityStatusPaused = 30,
    UnityStatusFailed = 40
};
@property (nonatomic, readwrite) NSURLSession *session;
@end

static NSString *const EBD_SESSION_ID_PREFIX = @"EBD_SESSION_INDENTIFIER_";
static NSString *const ON_COMPLETE_UNITY_METHOD = @"onCompleteDL";

@implementation EasyBgDownloader

/*
 * override init functions
 */
- (id)initWithProductNameAndGameObjName:(NSString *)prdName gameObjName:(NSString *)gameObjName cacheEnabled:(BOOL)cacheEnabled {
    if ((self = [super init])) {
        _prdName = prdName;
        _gameObjName = gameObjName;
        _cacheEnabled = cacheEnabled;
        
        _currentRequestURL = nil;
        _currentDownloadTask = nil;
        _currentProgress = 0.0f;
        _taskManager = [[EBDTaskManager alloc] initWithSession:[self getSession]];
        _taskIdList = [NSMutableDictionary dictionary];
        _destPathList = [NSMutableDictionary dictionary];
        _taskList = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)initEBD {
    
}
- (void)terminateEBD {
    
}
- (void)resumeEBD {
    
}
- (void)pauseEBD {
    
}


/*
 * Donwload Controls
 */
- (void)startDL:(NSString *)requestURL destPath:(NSString *)destPath {
    NSURL *url = [NSURL URLWithString:requestURL];
    NSURLSessionDownloadTask *downloadTask = [[self getSession] downloadTaskWithURL:url];
    
    [downloadTask resume];
    [_taskManager setTask:requestURL destPath:destPath downloadTask:downloadTask];
}

- (void)stopDL:(NSString *)requestURL {
    NSURLSessionDownloadTask *downloadTask = [_taskManager getDownloadTaskByURL:requestURL];
    if (downloadTask == nil) return;
    
    [downloadTask cancel];
    [_taskManager removeTask:requestURL];
}


/*
 * Donwload Status
 */
- (int)getStatus:(NSString *)requestURL {
    int status = UnityStatusNotInQueue;
    NSURLSessionDownloadTask *downloadTask = [_taskManager getDownloadTaskByURL:requestURL];
    if (downloadTask == nil) return status;
    
    switch (downloadTask.state) {
        case NSURLSessionTaskStateRunning:
            status = UnityStatusRunning;
            break;
        case NSURLSessionTaskStateSuspended:
            status = UnityStatusPaused;
            break;
        case NSURLSessionTaskStateCompleted:
            [self onComplete:downloadTask.taskIdentifier];
            status = UnityStatusNotInQueue;
            break;
        default:
            status = UnityStatusNotInQueue;
            break;
    }
    return status;
}


/*
 * Donwload Progress
 */
- (float)getProgress:(NSString *)requestURL {
    if (![_currentRequestURL isEqualToString:requestURL]) {
        [self changeCurrentTaskByURL:requestURL];
    }
    
    return _currentProgress;
}


/*
 * Download Event
 */
- (void)onComplete:(NSInteger)taskId {
    NSString *requestURL = [_taskManager getUrlByTaskId:taskId];
    NSString *destPath = [_taskManager getDestPath:taskId];
    if (requestURL != nil && destPath != nil) {
        [_taskManager removeTask:requestURL];
        NSString *taskInfo = [NSString stringWithFormat:@"%@,%@", requestURL, destPath];
        UnitySendMessage([_gameObjName UTF8String], [ON_COMPLETE_UNITY_METHOD UTF8String], [taskInfo UTF8String]);
    }
}

- (void)onFailed:(NSInteger)taskId {
    
}


/*
 * Platform Specific
 */
- (NSURLSession *)getSession {
    if (!self.session) {
        NSString *identifier = [EBD_SESSION_ID_PREFIX stringByAppendingString:_prdName];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
        
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    return self.session;
}

- (void)changeCurrentTaskByURL:(NSString *)requestURL {
    _currentRequestURL = requestURL;
    _currentDownloadTask = [_taskManager getDownloadTaskByURL:requestURL];
    _currentProgress = 0.0f;
}

- (void)saveFileWithPath:(NSData *)contents localPath:(NSString *)localPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createFileAtPath:localPath contents:[NSData data] attributes:nil];
    NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:localPath];
    [file writeData:contents];
}

- (void)pushLocalNotification:(NSString *)message {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = message;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}


/*
 * Delegate functions
 */
#pragma mark -- NSURLSessionDelegate --

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSString *ebdIdentifier = [EBD_SESSION_ID_PREFIX stringByAppendingString:_prdName];
    if (![session.configuration.identifier isEqualToString:ebdIdentifier]) {
        return;
    }
    
    [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            if (task.state == NSURLSessionTaskStateCompleted) {
                [self pushLocalNotification:[task.originalRequest.URL absoluteString]];
            }
        }
    }];
}

#pragma mark -- NSURLSessionTaskDelegate --

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error != nil) {
        //TODO : Error Handling
        NSLog(@"Download failed");
        [self onFailed:task.taskIdentifier];
    }
}

#pragma mark -- NSURLSessionDownloadDelegate --

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSData *data = [NSData dataWithContentsOfURL:location];
    if (data.length == 0) {
        //TODO : Error Handling
        NSLog(@"Download failed");
        [self onFailed:downloadTask.taskIdentifier];
        return;
    }
    
    NSString *requestURL = [downloadTask.originalRequest.URL absoluteString];
    NSLog(@"Complete task URL : %@", requestURL);
    NSInteger taskId = downloadTask.taskIdentifier;
    NSLog(@"Complete task Id : %ld", taskId);
    NSString *destPath = [_taskManager getDestPath:taskId];
    NSLog(@"Complete dest path : %@", destPath);
    
    if (!destPath) {
        //TODO : Error Handling
        NSLog(@"Saving avoided cause there is no dest path");
        return;
    }
    
    NSLog(@"Start saving");
    [self saveFileWithPath:data localPath:destPath];
    NSLog(@"Finish saving");
    [self onComplete:taskId];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (_currentDownloadTask != nil || _currentDownloadTask != downloadTask) return;
    
    _currentProgress = (float)((double)totalBytesWritten / (double)totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

#pragma mark -- UIApplicationDelegate --

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    
}

@end
