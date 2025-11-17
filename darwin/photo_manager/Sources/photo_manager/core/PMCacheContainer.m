#import "PMCacheContainer.h"
#import "PMAssetPathEntity.h"
#import <AVFoundation/AVAsset.h>

@implementation PMCacheContainer {
    NSMutableDictionary<NSString *, PMAssetEntity *> *map;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        map = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)putAssetEntity:(PMAssetEntity *)entity {
    @synchronized (map) {
        self->map[entity.id] = entity;
    }
}

- (PMAssetEntity *)getAssetEntity:(NSString *)id {
    return map[id];
}

- (void)clearCache {
    @synchronized (map) {
        [self->map removeAllObjects];
    }
}

@end
