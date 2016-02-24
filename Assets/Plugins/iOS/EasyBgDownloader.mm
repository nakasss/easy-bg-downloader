//
//  EasyBgDownloader.m
//  
//
//
//
//

#import <Foundation/Foundation.h>
#import "EasyBgDownloader.h"
#import "EBDTaskManager.h"


@interface EasyBgDownloader () <NSURLSessionDelegate> {
    NSString *_currentRequestURL;
    NSURLSessionDownloadTask *_currentDownloadTask;
    float _currentProgress;
    //EBDTaskManager *_taskManager;
    
    NSString *_prdName;
    NSString *_gameObjName;
    BOOL _cacheEnabled;
}
typedef NS_ENUM (int, EBDUnityStatus) {
    UnityStatusNotInQueue = -100,
    UnityStatusPending = 10,
    UnityStatusRunning = 20,
    UnityStatusPaused = 30,
    UnityStatusFailed = 40
};
@property (nonatomic, readwrite) NSURLSession *session;
@property (nonatomic, readwrite) EBDTaskManager *_taskManager;
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
    [[self getTaskManager] setTask:requestURL destPath:destPath downloadTask:downloadTask];
}

- (void)stopDL:(NSString *)requestURL {
    NSURLSessionDownloadTask *downloadTask = [[self getTaskManager] getDownloadTaskByURL:requestURL];
    if (downloadTask == nil) return;
    
    if ([_currentRequestURL isEqualToString:requestURL]) {
        [self initCurrentTask];
    }
    
    [downloadTask cancel];
    [[self getTaskManager] removeTask:requestURL];
}


/*
 * Donwload Status
 */
- (int)getStatus:(NSString *)requestURL {
    int status = UnityStatusNotInQueue;
    NSURLSessionDownloadTask *downloadTask = [[self getTaskManager] getDownloadTaskByURL:requestURL];
    if (downloadTask == nil) return status;
    
    switch (downloadTask.state) {
        case NSURLSessionTaskStateRunning:
            status = UnityStatusRunning;
            break;
        case NSURLSessionTaskStateSuspended:
            status = UnityStatusPaused;
            break;
        case NSURLSessionTaskStateCompleted:
            status = UnityStatusNotInQueue;
            break;
        case NSURLSessionTaskStateCanceling:
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
    if (!_currentRequestURL || ![_currentRequestURL isEqualToString:requestURL]) {
        [self changeCurrentTaskByURL:requestURL];
    }
    
    if (!_currentDownloadTask || _currentDownloadTask.state == NSURLSessionTaskStateCompleted || _currentDownloadTask.state == NSURLSessionTaskStateCanceling) {
        return 0.0f;
    }
    
    return _currentProgress;
}


/*
 * Download Event
 */
- (void)onComplete:(NSInteger)taskId {
    NSString *requestURL = [[self getTaskManager] getUrlByTaskId:taskId];
    
    if (requestURL) {
        NSString *destPath = [[self getTaskManager] getDestPath:taskId];
        [[self getTaskManager] removeTask:requestURL];
        
        if ([_currentRequestURL isEqualToString:requestURL]) {
            [self initCurrentTask];
        }
        
        if (destPath) {
            NSString *taskInfo = [NSString stringWithFormat:@"%@,%@", requestURL, destPath];
            UnitySendMessage([_gameObjName UTF8String], [ON_COMPLETE_UNITY_METHOD UTF8String], [taskInfo UTF8String]);
        }
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
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    return self.session;
}

- (EBDTaskManager *)getTaskManager {
    if (!self._taskManager) {
        self._taskManager = [[EBDTaskManager alloc] initWithSession:[self getSession]];
    }
    return self._taskManager;
}

- (void)changeCurrentTaskByURL:(NSString *)requestURL {
    _currentRequestURL = requestURL;
    _currentDownloadTask = [[self getTaskManager] getDownloadTaskByURL:requestURL];
    _currentProgress = 0.0f;
}

- (void)initCurrentTask {
    _currentRequestURL = nil;
    _currentDownloadTask = nil;
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
    if (error) {
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
    /*
    NSInteger taskId = [[self getTaskManager] getTaskId:requestURL];
    if (taskId == 0) {
        taskId = downloadTask.taskIdentifier;
    }
    */
    NSLog(@"Complete task Id : %ld", taskId);
    NSString *destPath = [[self getTaskManager] getDestPath:taskId];
    NSLog(@"Complete dest path : %@", destPath);
    
    if (!destPath) {
        //TODO : Error Handling
        NSLog(@"Avoided saving cause there is no dest path and remove Task");
        [[self getTaskManager] removeTask:requestURL];
        return;
    }
    
    NSLog(@"Start saving");
    [self saveFileWithPath:data localPath:destPath];
    NSLog(@"Finish saving");
    [self onComplete:taskId];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (_currentDownloadTask == nil || _currentDownloadTask != downloadTask) return;
    
    _currentProgress = (float)((double)totalBytesWritten / (double)totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

#pragma mark -- UIApplicationDelegate --

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    
}

@end
