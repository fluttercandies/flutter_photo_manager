#import <Foundation/Foundation.h>

@class PMAssetEntity;
@class AVPlayerItem;

@interface PMCacheContainer : NSObject

- (void)putAssetEntity:(PMAssetEntity *)entity;

- (PMAssetEntity *)getAssetEntity:(NSString *)id;

- (void)clearCache;

@end
