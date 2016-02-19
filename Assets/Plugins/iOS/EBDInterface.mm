//
//  EasyBgDownloaderInterface.m
//  Unity-iPhone
//
//  Created by Yuta Nakagawa on 2/18/16.
//
//

#include "EasyBgDownloader.h"
#import <Foundation/Foundation.h>

static const char *_productName = "SampleProduct";
static const char *_gameObjName = "GameObject";
static bool _cacheEnabled = NO;
static EasyBgDownloader *_Downloader;
static EasyBgDownloader *_GetDownloader() {
    if (!_Downloader) {
        _Downloader = [[EasyBgDownloader alloc] initWithProductNameAndAttachedGameObject:[[NSString alloc] initWithUTF8String:_productName] gameObjName:[[NSString alloc] initWithUTF8String:_gameObjName] cacheEnabled:_cacheEnabled];
    }
    return _Downloader;
}


/*
 * Interface
 */
extern "C" void EBDInterfaceInit(const char *productName, const char *gameObjName, bool cacheEnabled) {
    _productName = productName;
    _gameObjName = gameObjName;
    _cacheEnabled = cacheEnabled;
}

extern "C" void EBDInterfaceDestory() {
    
}

extern "C" void EBDInterfaceStartDownload(const char *requestedURL, const char *destPath) {
    [_GetDownloader() startDownload:[[NSString alloc] initWithUTF8String:requestedURL] destinationPath:[[NSString alloc] initWithUTF8String:destPath]];
}

extern "C" void EBDInterfaceStopDownload(const char *requestedURL) {
    [_GetDownloader() stopDownload:[[NSString alloc] initWithUTF8String:requestedURL]];
}

extern "C" float EBDInterfaceGetProgress(const char *requestedURL) {
    return [_GetDownloader() getProgress:[[NSString alloc] initWithUTF8String:requestedURL]];
}

extern "C" bool EBDInterfaceIsDownloading(const char *requestedURL) {
    return [_GetDownloader() isDownloading:[[NSString alloc] initWithUTF8String:requestedURL]];
}

//Test void
extern "C" void EasyBgDownloaderTestVoid() {
    NSLog(@"Log fron iOS Native void");
    UnitySendMessage("Downloader", "CallUnitySendMessage", "Native");
    return;
}
//Test int
extern "C" int EasyBgDownloaderTestReturnInt() {
    NSLog(@"Log fron iOS Native Return Int");
    return 1;
}
//Test values
extern "C" void EasyBgDownloaderTestValueInt(int i) {
    NSLog(@"Log fron iOS Native Value Int");
    return;
}
