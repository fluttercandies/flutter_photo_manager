//
// Created by jinglong cai on 2023/9/26.
//

#import "PMCacheManager.h"

@interface PMCacheDelegate : NSObject
@property(nonatomic, strong) PMCacheBlock onLoadBlock;
@property(nonatomic, strong) PMLoadResultHandler onLoaded;
@end

@implementation PMCacheDelegate
@end

@implementation PMCacheManager {

    // create dictionary to store temp file path and load progress handler
    // Key is temp file path, value is PMCacheDelegate

    NSMutableDictionary<NSString *, NSMutableArray<PMCacheDelegate *> *> *cacheMap;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        cacheMap = [NSMutableDictionary new];
    }
    return self;
}


+ (instancetype)sharedInstance {
    static PMCacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[PMCacheManager alloc] init];
    });
    return instance;
}


- (void)loadWithPath:(NSString *)path loadBlock:(PMCacheBlock)loadBlock onLoaded:(PMLoadResultHandler)onLoaded {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:path]) {
        onLoaded(nil);
        return;
    }
    NSMutableArray<PMCacheDelegate *> *array;
    @synchronized (cacheMap) {
        array = cacheMap[path];
        if (!array) {
            array = [NSMutableArray new];
        }
        cacheMap[path] = array;

        PMCacheDelegate *delegate = [PMCacheDelegate new];

        delegate.onLoadBlock = loadBlock;
        delegate.onLoaded = onLoaded;
        [array addObject:delegate];
    }

    // create temp file path with old path
    NSString *tempPath = [NSString stringWithFormat:@"%@.tmp", path];

    if ([fileManager fileExistsAtPath:tempPath]) {
        return;
    }

    // load file
    loadBlock(tempPath, ^(double progress) {
    }, ^(NSError *error) {
      @synchronized (cacheMap) {
          NSError *fileError;
          if (error) {
              [fileManager removeItemAtPath:tempPath error:&fileError];
          } else {
              [fileManager moveItemAtPath:tempPath toPath:path error:&fileError];
          }
          if (error == nil) {
              error = fileError;
          }
          for (PMCacheDelegate *delegateItem in array) {
              delegateItem.onLoaded(error);
          }
          [array removeAllObjects];
          [cacheMap removeObjectForKey:path];
      }
    });
}


@end