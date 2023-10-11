//
// Created by jinglong cai on 2023/9/26.
//

#import <Foundation/Foundation.h>

typedef void (^PMLoadProgressHandler)(double progress);

typedef void (^PMLoadResultHandler)(NSError *error);

typedef void (^PMCacheBlock)(NSString *tempPath, PMLoadProgressHandler progressHandler, PMLoadResultHandler resultHandler);

@interface PMCacheManager : NSObject

+ (instancetype)sharedInstance;

- (void)loadWithPath:(NSString *)path loadBlock:(PMCacheBlock)loadBlock onLoaded:(PMLoadResultHandler)onLoaded;

@end