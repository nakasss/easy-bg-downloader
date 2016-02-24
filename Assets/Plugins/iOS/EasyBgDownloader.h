//
//  EasyBgDownloader.h
//  
//
//
//
//


#ifndef EasyBgDownloader_h
#define EasyBgDownloader_h


@interface EasyBgDownloader : NSObject

- (id)initWithProductNameAndGameObjName:(NSString *)prdName gameObjName:(NSString *)gameObjName cacheEnabled:(BOOL)cacheEnabled;
- (void)initEBD;
- (void)terminateEBD;
- (void)resumeEBD;
- (void)pauseEBD;
- (void)startDL:(NSString *)requestURL destPath:(NSString *)destPath;
- (void)stopDL:(NSString *)requestURL;
- (int)getStatus:(NSString *)requestURL;
- (float)getProgress:(NSString *)requestURL;

@end


#endif /* EasyBgDownloader_h */
