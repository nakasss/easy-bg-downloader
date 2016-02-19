//
//  EasyBgDownloader.m
//  
//
//  Created by Yuta Nakagawa on 2/16/16.
//
//

#import <Foundation/Foundation.h>
#import "EasyBgDownloader.h"


@interface EasyBgDownloader () <NSURLSessionDelegate> {
    NSString *_currentRequestedURL;
    NSURLSessionDownloadTask *_currentDownloadTask;
    double _currentProgress;
    
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
@property (nonatomic, readwrite) NSURLSession *session;
@end

static NSString *const EBD_SESSION_ID_PREFIX = @"EBD_SESSION_INDENTIFIER_";
static NSString *const EBD_USERDEFAULTS_KEY_PREFIX = @"EBD_USERDEFAULTS_";
static NSString *const ON_COMPLETE_UNITY_METHOD = @"OnCompleteDownload";

@implementation EasyBgDownloader

/*
 * override init functions
 */
- (id)initWithProductNameAndAttachedGameObject:(NSString *)prdName gameObjName:(NSString *)gameObjName cacheEnabled:(BOOL)cacheEnabled {
    if ((self = [super init])) {
        _prdName = prdName;
        _gameObjName = gameObjName;
        _cacheEnabled = cacheEnabled;
        
        //init dictionary
        _taskIdList = [NSMutableDictionary dictionary];
        _destPathList = [NSMutableDictionary dictionary];
        _taskList = [NSMutableDictionary dictionary];
    }
    return self;
}

/*
 * Donwload functions : public
 */
- (void)startDownload:(NSString *)requestedURL destinationPath:(NSString *)destinationPath {
    if (!self.session) {
        [self createSessionWithIdentifier];
    }
    
    //Set download task
    NSURL *url = [NSURL URLWithString:requestedURL];
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:url];
    
    //Store task
    [self storeTask:requestedURL destPath:destinationPath downloadTask:downloadTask];
    
    //Start download
    [downloadTask resume];
}

- (void)stopDownload:(NSString *)requestedURL {
    NSURLSessionDownloadTask *downloadTask = [self getTaskByURL:requestedURL];
    if (!downloadTask) {
        return;
    }
    
    //Stop Download
    if (_cacheEnabled) {
        
    } else {
        [downloadTask cancel];
        [self removeTask:requestedURL];
    }
}

- (double)getProgress:(NSString *)requestedURL {
    if (![_currentRequestedURL isEqualToString:requestedURL]) {
        [self changeCurrentTaskByURL:requestedURL];
    }
    
    return _currentProgress;
}

- (bool)isDownloading:(NSString *)requestedURL {
    NSInteger state = [self getCurrentStatus:requestedURL];
    
    if (state == NSURLSessionTaskStateRunning) {
        return true;
    } else {
        return false;
    }
}

- (NSInteger)getCurrentStatus:(NSString *)requestedURL {
    if (![_currentRequestedURL isEqualToString:requestedURL]) {
        [self changeCurrentTaskByURL:requestedURL];
    }
    
    return _currentDownloadTask.state;
}

- (void)onComplete:(NSString *)requestedURL {
    UnitySendMessage([_gameObjName UTF8String], [ON_COMPLETE_UNITY_METHOD UTF8String], [requestedURL UTF8String]);
}

/*
 * Other Functions : private
 */
//Get session by indentifier
- (void)createSessionWithIdentifier {
    //Get session configuration
    NSString *identifier = [EBD_SESSION_ID_PREFIX stringByAppendingString:_prdName];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
    
    //Get session
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
}

//Change current task
- (void)changeCurrentTaskByURL:(NSString *)requestedURL {
    _currentRequestedURL = requestedURL;
    _currentDownloadTask = [self getTaskByURL:_currentRequestedURL];
    _currentProgress = 0;
}

//Save Task
- (void)storeTask:(NSString *)requestedURL destPath:(NSString *)destPath downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask {
    //Set Id
    NSInteger taskId = downloadTask.taskIdentifier;
    [self saveTaskIdByUrl:taskId requestedUrl:requestedURL];
    [self saveTaskIdbyURLToUD:taskId url:requestedURL];
    //Set Destination Path
    [self saveDestPathByTaskId:destPath taskId:taskId];
    [self saveDestPathByTaskIdToUD:destPath taskId:taskId];
    //Set Task
    [self saveTaskById:downloadTask taskId:taskId];
}
//Save TaskId
- (void)saveTaskIdByUrl:(NSInteger)taskId requestedUrl:(NSString *)requestedUrl {
    [_taskIdList setObject:[[NSNumber alloc] initWithInteger:taskId] forKey:requestedUrl];
}
//Save DestPath
- (void)saveDestPathByTaskId:(NSString *)destPath taskId:(NSInteger)taskId {
    [_destPathList setObject:destPath forKey:[[NSNumber alloc] initWithInteger:taskId]];
}
//Save Download Task
- (void)saveTaskById:(NSURLSessionDownloadTask *)task taskId:(NSInteger)taskId {
    [_taskList setObject:task forKey:[[NSNumber alloc] initWithInteger:taskId]];
}
//Remove Task
- (void)removeTask:(NSString *)requestedURL {
    NSInteger taskId = [self getTaskIdByURL:requestedURL];
    
    //remove task
    if (taskId != -1) {
        [_taskIdList removeObjectForKey:requestedURL];
        [self removeTaskIdByUrlFromUD:requestedURL];
        [_destPathList removeObjectForKey:[[NSNumber alloc] initWithInteger:taskId]];
        [self removeDestPathByTaskIdFromUD:taskId];
        [_taskList removeObjectForKey:[[NSNumber alloc] initWithInteger:taskId]];
    }
}
//Get Task by url
- (NSURLSessionDownloadTask *)getTaskByURL:(NSString *)requestedURL {
    NSInteger taskID = [self getTaskIdByURL:requestedURL];
    if (taskID != -1) {
        return [self getTaskById:taskID];
    } else {
        return nil;
    }
}
//Get Task by id
- (NSURLSessionDownloadTask *)getTaskById:(NSInteger)taskId {
    NSURLSessionDownloadTask *task = [_taskList objectForKey:[[NSNumber alloc] initWithInteger:taskId]];
    if (task) {
        return task;
    } else {
        
        //TODO : refresh in other place
        /*
        if (!self.session) {
            [self createSessionWithIdentifier];
        }
        
        [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            for (NSURLSessionDownloadTask *task in downloadTasks) {
                if (taskId == task.taskIdentifier) {
                    //save to dictionary
                    [self saveTaskById:task taskId:taskId];
                    break;
                }
            }
        }];
        */
        
        return nil;
    }
}
//Get destination path by URL
- (NSString *)getDestPathByURL:(NSString *)requestedURL {
    NSInteger taskID = [self getTaskIdByURL:requestedURL];
    if (taskID != -1) {
        return [self getDestPathById:taskID];
    } else {
        return nil;
    }
}
//Get destination path by id
- (NSString *)getDestPathById:(NSInteger)taskId {
    NSString *destPath = [_destPathList objectForKey:[[NSNumber alloc] initWithInteger:taskId]];
    if (destPath) {
        return destPath;
    } else {
        //try to get destination path from UserDefault
        destPath = [self getDestPathByTaskIdFromUD:taskId];
        if (destPath) {
            //save to dictionary
            [self saveDestPathByTaskId:destPath taskId:taskId];
            return destPath;
        } else {
            return nil;
        }
    }
    return [_destPathList objectForKey:[[NSNumber alloc] initWithInteger:taskId]];
}
//Get TaskID by url
- (NSInteger)getTaskIdByURL:(NSString *)requestedURL {
    NSNumber *taskIdObj = [_taskIdList objectForKey:requestedURL];
    if (taskIdObj) {
        return [taskIdObj integerValue];
    } else {
        //try to get id from UserDefault
        NSInteger taskId = [self getTaskIdByUrlFromUD:requestedURL];
        if (taskId != 0) {
            //save to dictionary
            [self saveTaskIdByUrl:taskId requestedUrl:requestedURL];
            return taskId;
        } else {
            return -1;
        }
    }
}

//Save TaskId by URL in User Default
- (void)saveTaskIdbyURLToUD:(NSInteger)taskId url:(NSString *)url {
    NSString *keyUrl = [EBD_USERDEFAULTS_KEY_PREFIX stringByAppendingString:url];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setInteger:taskId forKey:keyUrl];
    [userDefault synchronize];
}
//Save Destination path by taskId in User Default
- (void)saveDestPathByTaskIdToUD:(NSString *)destPath taskId:(NSInteger)taskId {
    NSString *keyTaskId = [EBD_USERDEFAULTS_KEY_PREFIX stringByAppendingString:[NSString stringWithFormat:@"d", taskId]];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:destPath forKey:keyTaskId];
    [userDefault synchronize];
}
//Remove TaskId by URL from User Default
- (void)removeTaskIdByUrlFromUD:(NSString *)url {
    NSString *keyUrl = [EBD_USERDEFAULTS_KEY_PREFIX stringByAppendingString:url];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:keyUrl];
    [userDefault synchronize];
}
//Remove Destination by taskId from User Default
- (void)removeDestPathByTaskIdFromUD:(NSInteger)taskId {
    NSString *keyTaskId = [EBD_USERDEFAULTS_KEY_PREFIX stringByAppendingString:[NSString stringWithFormat:@"d", taskId]];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:keyTaskId];
    [userDefault synchronize];
}
//Get TaskId by URL from User Default
- (NSInteger)getTaskIdByUrlFromUD:(NSString *)url {
    NSString *keyUrl = [EBD_USERDEFAULTS_KEY_PREFIX stringByAppendingString:url];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    return [userDefault integerForKey:keyUrl];
}
//Get Destination path by taskId from User Default
- (NSString *)getDestPathByTaskIdFromUD:(NSInteger)taskId {
    NSString *keyTaskId = [EBD_USERDEFAULTS_KEY_PREFIX stringByAppendingString:[NSString stringWithFormat:@"d", taskId]];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    return [userDefault stringForKey:keyTaskId];
}


//Save file at local
- (void)saveFileWithPath:(NSData *)contents localPath:(NSString *)localPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createFileAtPath:localPath contents:[NSData data] attributes:nil];
    NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:localPath];
    [file writeData:contents];
}

/*
 * Delegate functions
 */
#pragma mark -- NSURLSessionDelegate --

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
}

#pragma mark -- NSURLSessionTaskDelegate --

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error == nil) {
        NSLog(@"Download succeeded");
    } else {
        NSLog(@"Download failed");
    }
}

#pragma mark -- NSURLSessionDownloadDelegate --

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSData *data = [NSData dataWithContentsOfURL:location];
    if (data.length == 0) {
        //error occured
        return;
    }
    
    NSString *requestedURL = [downloadTask.originalRequest.URL absoluteString];
    NSLog(@"Complete task URL : %@", requestedURL);
    NSInteger taskId = downloadTask.taskIdentifier;
    NSLog(@"Complete task Id : %ld", taskId);
    NSString *destPath = [self getDestPathById:taskId];
    NSLog(@"Complete dest path : %@", destPath);
    
    if (!destPath) {
        NSLog(@"Saving avoided cause there is no dest path");
        return;
    }
    
    NSLog(@"Start saving");
    [self saveFileWithPath:data localPath:destPath];
    NSLog(@"Finish saving");
    [self removeTask:requestedURL];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (_currentDownloadTask != downloadTask) return;
    
    _currentProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

#pragma mark -- UIApplicationDelegate --

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    
}

@end
