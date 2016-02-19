//
//  EasyBgDownloader.m
//  
//
//  Created by Yuta Nakagawa on 2/16/16.
//
//

#import <Foundation/Foundation.h>
#import "DownloadTaskManager.h"


@interface DownloadTaskManager () {
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

@implementation DownloadTaskManager


/*
 * Other Functions : private
 */

//Store Task
- (void)storeTask:(NSString *)requestedURL destPath:(NSString *)destPath downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask {
    if (!_taskIdList) {
        _taskIdList = [NSMutableDictionary dictionary];
    }
    if (!_taskList) {
        _taskList = [NSMutableDictionary dictionary];
    }
    if (!_destPathList) {
        _destPathList = [NSMutableDictionary dictionary];
    }
    
    //Set Id
    NSNumber *taskID = [[NSNumber alloc] initWithInteger:downloadTask.taskIdentifier];
    [_taskIdList setObject:taskID forKey:requestedURL];
    //Set Destination Path
    [_destPathList setObject:destPath forKey:taskID];
    //Set Task
    [_taskList setObject:downloadTask forKey:taskID];
}
//Remove Task
- (void)removeTask:(NSString *)requestedURL {
    if (!_taskIdList || !_destPathList || !_taskList) {
        return;
    }
    
    NSInteger taskId = [self getTaskIdByURL:requestedURL];
    
    //remove task
    if (taskId != -1) {
        [_taskIdList removeObjectForKey:requestedURL];
        [_destPathList removeObjectForKey:[[NSNumber alloc] initWithInteger:taskId]];
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
    if (!_taskList) {
        return nil;
    }
    
    return [_taskList objectForKey:[[NSNumber alloc] initWithInteger:taskId]];
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
    if (!_destPathList) {
        return nil;
    }
    
    return [_destPathList objectForKey:[[NSNumber alloc] initWithInteger:taskId]];
}
//Get TaskID by url
- (NSInteger)getTaskIdByURL:(NSString *)requestedURL {
    if (!_taskIdList) {
        return -1;
    }
    
    NSNumber *taskID = [_taskIdList objectForKey:requestedURL];
    if (taskID) {
        return [taskID integerValue];
    } else {
        return -1;
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


@end
