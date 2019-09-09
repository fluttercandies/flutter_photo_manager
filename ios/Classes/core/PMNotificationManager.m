//
// Created by Caijinglong on 2019-09-09.
//

#import <Flutter/Flutter.h>
#import "PMNotificationManager.h"
#import "ConvertUtils.h"
#import <Photos/PHPhotoLibrary.h>
#import <Photos/Photos.h>

@interface PMNotificationManager () <PHPhotoLibraryChangeObserver>
@end

@implementation PMNotificationManager {
    FlutterMethodChannel *channel;
    BOOL _notifying;
}

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        self.registrar = registrar;
        channel = [FlutterMethodChannel methodChannelWithName:@"top.kikt/photo_manager/notify" binaryMessenger:[registrar messenger]];
        _notifying = NO;
    }

    return self;
}

+ (instancetype)managerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    return [[self alloc] initWithRegistrar:registrar];
}

- (void)startNotify {
    PHPhotoLibrary *library = PHPhotoLibrary.sharedPhotoLibrary;
    [library registerChangeObserver:self];
    _notifying = YES;
}

- (void)stopNotify {
    PHPhotoLibrary *library = PHPhotoLibrary.sharedPhotoLibrary;
    [library unregisterChangeObserver:self];
    _notifying = NO;
}

#pragma "photo library notify"

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHObjectChangeDetails *details = [changeInstance changeDetailsForObject:[PHObject new]];
    PHObject *object = details.objectAfterChanges;

    if ([object isMemberOfClass:[PHAssetCollection class]]) {
        PHAssetCollection *collection = (PHAssetCollection *) object;
        [self onAssetCollectionChanged:collection];
    } else if ([object isMemberOfClass:[PHAsset class]]) {
        PHAsset *asset = (PHAsset *) object;
        [self onAssetChanged:asset];
    } else if ([object isMemberOfClass:[PHCollectionList class]]) {
        PHCollectionList *collectionList = (PHCollectionList *) object;
        [self onCollectionListChanged:collectionList];
    }
}

- (void)onAssetChanged:(PHAsset *)asset {
    [channel invokeMethod:@"change" arguments:
            @{
                    @"ios-asset": [ConvertUtils convertPHAssetToMap:asset]
            }
    ];
}

- (void)onAssetCollectionChanged:(PHAssetCollection *)collection {
    [channel invokeMethod:@"change" arguments:
            @{
                    @"ios-collection": @{@"id": collection.localIdentifier,}
            }
    ];
}

- (void)onCollectionListChanged:(PHCollectionList *)list {
    [channel invokeMethod:@"change" arguments:
            @{
                    @"ios-collectionList": @{@"id": list.localIdentifier,}
            }
    ];
}

- (BOOL)isNotifying {
    return _notifying;
}
@end