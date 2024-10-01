#import "PMNotificationManager.h"
#import "PMConvertUtils.h"
#import "core/PMLogUtils.h"

@interface PMNotificationManager () <PHPhotoLibraryChangeObserver>
@end

@implementation PMNotificationManager {
    FlutterMethodChannel *channel;
    BOOL _notifying;
    PHFetchResult<PHAsset *> *result;
    BOOL isDetach;
}

- (void)dealloc {
    [self detach];
}

- (instancetype)initWithRegistrar:
    (NSObject <FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        self.registrar = registrar;
        channel = [FlutterMethodChannel
            methodChannelWithName:@"com.fluttercandies/photo_manager/notify"
                  binaryMessenger:[registrar messenger]];
        _notifying = NO;
    }
    isDetach = NO;
    return self;
}

+ (instancetype)managerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    return [[self alloc] initWithRegistrar:registrar];
}

- (void)detach {
    isDetach = YES;
    if (_notifying) {
        [self stopNotify];
    }
    [channel setMethodCallHandler:nil];
}

- (void)startNotify {
    if (isDetach) {
        return;
    }
    [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
    _notifying = YES;
    [self refreshFetchResult];
}

- (void)stopNotify {
    if (!_notifying || isDetach) {
        return;
    }
    [PHPhotoLibrary.sharedPhotoLibrary unregisterChangeObserver:self];
    _notifying = NO;
}

#pragma "photo library notify"

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if (isDetach || !result) {
        return;
    }
    PHFetchResultChangeDetails *details = [changeInstance changeDetailsForFetchResult:result];
    NSUInteger oldCount = result.count;
    [self refreshFetchResult];
    if (isDetach || !result) {
        return;
    }
    NSUInteger newCount = result.count;
    NSMutableDictionary *detailResult = [self convertChangeDetailsToNotifyDetail:details];
    detailResult[@"oldCount"] = @(oldCount);
    detailResult[@"newCount"] = @(newCount);

    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"on change result = %@", detailResult]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->channel invokeMethod:@"change" arguments:detailResult];
    });
}

- (void)refreshFetchResult {
    if (isDetach) {
        return;
    }
    result = [self getLastAssets];
}

- (NSMutableDictionary *)convertChangeDetailsToNotifyDetail:(PHFetchResultChangeDetails *)details {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    NSArray<PHObject *> *changedObjects = details.changedObjects;
    NSArray<PHObject *> *insertedObjects = details.insertedObjects;
    NSArray<PHObject *> *removedObjects = details.removedObjects;

    [self addToResult:dictionary key:@"update" objects:changedObjects];
    [self addToResult:dictionary key:@"create" objects:insertedObjects];
    [self addToResult:dictionary key:@"delete" objects:removedObjects];

    return dictionary;
}

- (void)addToResult:(NSMutableDictionary *)dictionary
                key:(NSString *)key
            objects:(NSArray<PHObject *> *)changedObjects {
    NSMutableArray *items = [NSMutableArray new];

    for (PHObject *object in changedObjects) {
        if ([object isMemberOfClass:PHAsset.class]) {
            PHAsset *asset = (PHAsset *) object;
            NSMutableDictionary *itemDict = [NSMutableDictionary new];
            PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection
                fetchAssetCollectionsContainingAsset:asset
                                            withType:PHAssetCollectionTypeAlbum
                                             options:nil];
            itemDict[@"id"] = object.localIdentifier;
            NSMutableArray *collectionArray = [NSMutableArray new];
            for (PHAssetCollection *collection in collections) {
                NSDictionary *collectionDict = @{
                    @"id": collection.localIdentifier,
                    @"title": collection.localizedTitle
                };
                [collectionArray addObject:collectionDict];
            }
            [items addObject:itemDict];
        }
    }

    dictionary[key] = items;
}

- (PHFetchResult<PHAsset *> *)getLastAssets {
#if __IPHONE_14_0
    if (@available(iOS 14, *)) {
        if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusLimited) {
            return [PHAsset fetchAssetsWithOptions:nil];
        }
    }
#endif
    if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized) {
        return [PHAsset fetchAssetsWithOptions:nil];
    }
    return nil;
}

- (BOOL)isNotifying {
    return _notifying;
}
@end
