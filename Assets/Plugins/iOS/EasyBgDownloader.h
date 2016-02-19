//
//  EasyBgDownloader.h
//  Unity-iPhone
//
//  Created by Yuta Nakagawa on 2/18/16.
//
//


#ifndef EasyBgDownloader_h
#define EasyBgDownloader_h


@interface EasyBgDownloader : NSObject

- (id)initWithProductNameAndAttachedGameObject:(NSString *)prdName gameObjName:(NSString *)gameObjName cacheEnabled:(BOOL)cacheEnabled;
- (void)startDownload:(NSString *)requestedURL destinationPath:(NSString *)destinationPath;
- (void)stopDownload:(NSString *)requestedURL;
- (double)getProgress:(NSString *)requestedURL;
- (bool)isDownloading:(NSString *)requestedURL;

@end


#endif /* EasyBgDownloader_h */
