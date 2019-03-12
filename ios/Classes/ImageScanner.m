//
// Created by Caijinglong on 2018/9/10.
//
#import "ImageScanner.h"
#import <Flutter/FlutterChannels.h>
#import <Photos/PHAsset.h>
#import <Photos/PHCollection.h>
#import <Photos/Photos.h>
#import <Photos/PHFetchOptions.h>
#import <Photos/PHImageManager.h>
#import <Photos/PHPhotoLibrary.h>
#import <Foundation/Foundation.h>
#import "MD5Utils.h"
#import "PHAsset+PHAsset_checkType.h"
#import "AssetEntity.h"
#import "Reply.h"
#import "PhotoChangeObserver.h"

@interface ImageScanner ()

@property(nonatomic, strong) NSMutableArray<PHCollection *> *galleryArray;
@property(nonatomic, strong) NSMutableDictionary<NSString *, PHCollection *> *idCollectionDict;
@property(nonatomic, strong) NSMutableDictionary<NSString *, PHAsset *> *idAssetDict;

@property(nonatomic) dispatch_queue_t asyncQueue;

@property(nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<PHAsset *> *> *idVideoArrayDict;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<PHAsset *> *> *idImageArrayDict;


@property(nonatomic, strong) PhotoChangeObserver *observer;

@end

@implementation ImageScanner {
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _galleryArray = [NSMutableArray new];
        _idCollectionDict = [NSMutableDictionary new];
        _idAssetDict = [NSMutableDictionary new];
        _asyncQueue = dispatch_queue_create("asyncQueue", nil);

        _idVideoArrayDict = [NSMutableDictionary new];
        _idImageArrayDict = [NSMutableDictionary new];

        _observer = [PhotoChangeObserver new];
    }

    return self;
}


- (void)requestPermissionWithResult:(FlutterResult)result {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [_observer initWithRegister:self.registrar];
            result(@1);
        } else {
            result(@0);
        }
    }];

}

- (void)getGalleryIdList:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        BOOL cached = [call.arguments boolValue];
        if (!cached) {
            [self refreshGallery];
            NSMutableArray *arr = [NSMutableArray new];
            [self refreshGalleryDict:arr];
            result(arr);
        } else {
            NSMutableArray *arr = [NSMutableArray new];
            for (PHCollection *collection in self->_galleryArray) {
                [arr addObject:collection.localIdentifier];
            }
            result(arr);
        }
    });
}

- (void)refreshGalleryDict:(NSMutableArray *)arr {
    if (_idCollectionDict) {
        [_idCollectionDict removeAllObjects];
    } else {
        _idCollectionDict = [NSMutableDictionary new];
    }

    for (PHCollection *collection in _galleryArray) {
        if (arr) {
            [arr addObject:collection.localIdentifier];
        }
        _idCollectionDict[collection.localIdentifier] = collection;
    }
}

- (void)refreshGallery {
    NSMutableArray<PHCollection *> *galleryArray = [NSMutableArray array];

    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];

    PHFetchResult *smartAlbumsFetchResult =
            [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                     subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                     options:nil];
    PHAssetCollection *collection = [smartAlbumsFetchResult objectAtIndex:0];
    [galleryArray addObject:collection];

    PHFetchResult *smartAlbumsFetchResult1 =
            [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:fetchOptions];
    for (PHAssetCollection *sub in smartAlbumsFetchResult1) {
        [galleryArray addObject:sub];
    }

    self.galleryArray = galleryArray;
}

- (void)getGalleryNameWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        NSArray *ids = call.arguments;
        NSMutableArray<NSString *> *r = [NSMutableArray new];
        for (NSString *id in ids) {
            PHCollection *collection = _idCollectionDict[id];
            [r addObject:collection.localizedTitle];
        }
        result(r);
    });
}

- (void)getImageListWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
    dispatch_async(_asyncQueue, ^{
        if (!_idAssetDict) {
            _idAssetDict = [NSMutableDictionary new];
        }

        NSString *pathId = call.arguments;
        PHCollection *collection = _idCollectionDict[pathId];

        PHFetchOptions *opt = [PHFetchOptions new];
        //    opt.sortDescriptors = @[[NSSortDescriptor
        //    sortDescriptorWithKey:@"creationDate" ascending:true]];

        PHFetchResult<PHAssetCollection *> *r =
                [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collection.localIdentifier]
                                                                     options:opt];

        NSMutableArray<NSString *> *arr = [NSMutableArray new];

        for (PHAssetCollection *assetCollection in r) {
            PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection
                                                                                  options:opt];
            for (PHAsset *asset in fetchResult) {
                NSString *id = asset.localIdentifier;
                _idAssetDict[id] = asset;
                [arr addObject:id];
            }
        }

        flutterResult(arr);
    });
}

- (void)filterAssetWithBlock:(asset_block)block {
    [self refreshGallery];
    PHFetchOptions *opt = [PHFetchOptions new];
    for (PHCollection *collection in self.galleryArray) {
        PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection
                fetchAssetCollectionsWithLocalIdentifiers:@[collection.localIdentifier] options:opt];

        for (PHAssetCollection *assetCollection in fetchResult) {
            if (![assetCollection isKindOfClass:[PHAssetCollection class]]) continue;
            
            PHFetchResult<PHAsset *> *assetResult = [PHAsset
                    fetchAssetsInAssetCollection:assetCollection options:opt];
            for (PHAsset *asset in assetResult) {
                _idAssetDict[asset.localIdentifier] = asset;
                block(assetCollection, asset);
            }
        }
    }
}

- (void)forEachAssetCollection:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
    dispatch_async(_asyncQueue, ^{
        if (_idAssetDict) {
            [_idAssetDict removeAllObjects];
        } else {
            _idAssetDict = [NSMutableDictionary new];
        }

        NSMutableArray<NSString *> *arr = [NSMutableArray new];

        NSArray<PHCollection *> *collectionArray = [self->_idCollectionDict allValues];
        PHFetchOptions *opt = [PHFetchOptions new];

        for (PHAssetCollection *assetCollection in collectionArray) {
            PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection
                                                                                  options:opt];
            for (PHAsset *asset in fetchResult) {
                NSString *id = asset.localIdentifier;
                _idAssetDict[id] = asset;
                if (![arr containsObject:id]) {
                    [arr addObject:id];
                }
            }
        }

        flutterResult(arr);
    });
}

- (void)getThumbPathWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
    dispatch_async(_asyncQueue, ^{
        PHImageManager *manager = PHImageManager.defaultManager;

        NSString *imgId = call.arguments;

        PHAsset *asset = _idAssetDict[imgId];

        [manager requestImageForAsset:asset
                           targetSize:CGSizeMake(100, 100)
                          contentMode:PHImageContentModeAspectFill
                              options:[PHImageRequestOptions new]
                        resultHandler:^(UIImage *result, NSDictionary *info) {

                            BOOL downloadFinined =
                                    ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                            ![info objectForKey:PHImageErrorKey] &&
                                            ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                            if (!downloadFinined) {
                                flutterResult(nil);
                                return;
                            }

                            NSData *data = UIImageJPEGRepresentation(result, 95);
                            NSString *path = [self writeThumbFileWithAssetId:asset imageData:data];
                            flutterResult(path);
                        }];
    });
}

- (void)getThumbBytesWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult reply:(Reply *)reply {
    dispatch_async(_asyncQueue, ^{
        PHImageManager *manager = PHImageManager.defaultManager;

        NSArray *args = call.arguments;
        NSString *imgId = [args objectAtIndex:0];
        int width = [((NSString *) [args objectAtIndex:1]) intValue];
        int height = [((NSString *) [args objectAtIndex:2]) intValue];
        // NSLog(@"request width = %i , height = %i",width,height);

        PHAsset *asset = self->_idAssetDict[imgId];
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        [options setNetworkAccessAllowed:YES];
        [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            if (progress != 1.0) {
                return;
            }
            [self getThumbBytesWithCall:call result:flutterResult reply:reply];
        }];

        __weak ImageScanner *wSelf = self;
        [manager requestImageForAsset:asset
                           targetSize:CGSizeMake(width, height)
                          contentMode:PHImageContentModeAspectFill
                              options:options
                        resultHandler:^(UIImage *result, NSDictionary *info) {
//                            NSLog(@"image width = %f , height = "
//                                  "%f", result.size.width, result.size.height);
                            BOOL downloadFinined =
                                    ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                            ![info objectForKey:PHImageErrorKey] &&
                                            ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                            if (!downloadFinined) {
                                return;
                            }
                            NSData *data = UIImageJPEGRepresentation(result, 100);

                            if (reply.isReply) {
                                return;
                            }

                            reply.isReply = YES;

                            if (!data) {
                                flutterResult([FlutterStandardTypedData typedDataWithBytes:[NSData new]]);
                                return;
                            }

                            FlutterStandardTypedData *typedData = [FlutterStandardTypedData typedDataWithBytes:data];
                            flutterResult(typedData);
                        }];
    });
}

- (NSString *)writeThumbFileWithAssetId:(PHAsset *)asset imageData:(NSData *)imageData {
    NSString *homePath = NSTemporaryDirectory();

    //    NSURL *url = [[NSURL alloc] initWithString:homePath];

    NSFileManager *manager = NSFileManager.defaultManager;

    NSMutableString *path = [NSMutableString stringWithString:homePath];
    NSString *dir = [path stringByAppendingPathComponent:@".thumb"];

    BOOL createSuccess = [manager createDirectoryAtPath:dir attributes:nil];

    NSMutableString *p = [[NSMutableString alloc] initWithString:dir];
    NSString *filePath = [p
            stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"%@.jpg", [MD5Utils getmd5WithString:asset.localIdentifier]]];
    if ([manager fileExistsAtPath:filePath]) {
        return filePath;
    }

    BOOL createFileResult = [manager createFileAtPath:filePath contents:imageData attributes:nil];
    return filePath;
}

- (void)getFullFileWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult reply:(Reply *)reply {

    NSDictionary *params = [call arguments];

    dispatch_async(_asyncQueue, ^{
        PHImageManager *manager = PHImageManager.defaultManager;
        BOOL isOri = [params[@"isOrigin"] boolValue];
        NSString *imgId = params[@"id"];

        PHAsset *asset = self->_idAssetDict[imgId];
        __weak ImageScanner *wSelf = self;

        if ([asset isImage]) {
            PHImageRequestOptions *options = [PHImageRequestOptions new];
            options.resizeMode = PHImageRequestOptionsResizeModeFast;

            [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                if (progress == 1.0) {
                    [self getFullFileWithCall:call result:flutterResult reply:reply];
                }
            }];

            if (!isOri) {
                [manager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                    BOOL downloadFinish = [self isFinishWithInfo:info];
                    if (!downloadFinish) {
                        return;
                    }
                    NSData *data = UIImageJPEGRepresentation(result, 100);

                    if (reply.isReply) {
                        return;
                    }

                    reply.isReply = YES;

                    reply.isReply = YES;

                    NSString *path = [wSelf writeFullFileWithAssetId:asset imageData:data postfix:@"_origin"];
                    flutterResult(path);
                }];
            } else {
                [manager requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI,
                        UIImageOrientation orientation, NSDictionary *info) {

                    BOOL downloadFinined = [self isFinishWithInfo:info];
                    if (!downloadFinined) {
                        return;
                    }

                    if (reply.isReply) {
                        return;
                    }

                    reply.isReply = YES;

                    NSString *path = [wSelf writeFullFileWithAssetId:asset imageData:imageData postfix:@"_exif"];
                    flutterResult(path);
                }];
            }
        } else if ([asset isVideo]) {
            [self writeFullVideoFileWithAsset:asset result:flutterResult reply:reply];
        } else {
            flutterResult(nil);
        }
    });
}

- (BOOL)isFinishWithInfo:(NSDictionary *)info {
    return ![info[PHImageCancelledKey] boolValue] &&
            !info[PHImageErrorKey] &&
            ![info[PHImageResultIsDegradedKey] boolValue];
}

- (void)writeFullVideoFileWithAsset:(PHAsset *)asset result:(FlutterResult)result reply:(Reply *)reply {
    dispatch_async(_asyncQueue, ^{
        NSString *homePath = NSTemporaryDirectory();
        NSFileManager *manager = NSFileManager.defaultManager;

        NSMutableString *path = [NSMutableString stringWithString:homePath];

        NSString *filename = [asset valueForKey:@"filename"];

        NSString *dirPath = [NSString stringWithFormat:@"%@/%@", homePath, @".video"];
        [manager createDirectoryAtPath:dirPath attributes:@{}];

        [path appendFormat:@"%@/%@", @".video", filename];
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        if ([manager fileExistsAtPath:path]) {
            NSLog(@"read cache from %@", path);
            reply.isReply = YES;
            result(path);
            return;
        }

        [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            if (progress == 1.0) {
                [self writeFullVideoFileWithAsset:asset result:result reply:reply];
            }
        }];

        [options setNetworkAccessAllowed:YES];

        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix,
                NSDictionary *_Nullable info) {

            BOOL downloadFinined =
                    ![info[PHImageCancelledKey] boolValue] &&
                            !info[PHImageErrorKey] &&
                            ![info[PHImageResultIsDegradedKey] boolValue];
            if (!downloadFinined) {
                result(nil);
                return;
            }

            if (reply.isReply) {
                return;
            }

            reply.isReply = YES;

            NSURL *fileRUL = [asset valueForKey:@"URL"];
            NSData *beforeVideoData = [NSData dataWithContentsOfURL:fileRUL];  //未压缩的视频流
            BOOL createResult = [manager createFileAtPath:path contents:beforeVideoData attributes:@{}];
            NSLog(@"write file to %@ , size = %lu , createResult = %@", path,
                    (unsigned long) beforeVideoData.length, createResult ? @"true" : @"false");
            result(path);
        }];
    });
}

- (NSString *)writeFullFileWithAssetId:(PHAsset *)asset imageData:(NSData *)imageData postfix:(NSString *)postfix {
    NSString *homePath = NSTemporaryDirectory();
    NSFileManager *manager = NSFileManager.defaultManager;

    NSMutableString *path = [NSMutableString stringWithString:homePath];
    [path appendString:@".images"];

    BOOL createSuccess = [manager createDirectoryAtPath:path attributes:@{}];

    [path appendString:@"/"];
    [path appendString:[MD5Utils getmd5WithString:asset.localIdentifier]];
    if (postfix) {
        [path appendString:postfix];
    }
    [path appendString:@".jpg"];

    if ([manager fileExistsAtPath:path]) {
        return path;
    }

    [manager createFileAtPath:path contents:imageData attributes:@{}];
    return path;
}

- (void)getBytesWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult reply:(Reply *)reply {
    dispatch_async(_asyncQueue, ^{
        NSString *imgId = call.arguments;
        PHAsset *asset = self->_idAssetDict[imgId];

        PHImageManager *manager = PHImageManager.defaultManager;
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        [options setNetworkAccessAllowed:YES];
        [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            if (progress == 1.0) {
                [self getBytesWithCall:call result:flutterResult reply:reply];
            }
        }];
        [manager requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {

            BOOL downloadFinined =
                    ![info[PHImageCancelledKey] boolValue] &&
                            !info[PHImageErrorKey] &&
                            ![info[PHImageResultIsDegradedKey] boolValue];
            if (!downloadFinined) {
                flutterResult(nil);
                return;
            }

            if (reply.isReply) {
                return;
            }

            reply.isReply = YES;

            NSArray *arr = [ImageScanner convertNSData:imageData];
            flutterResult(arr);
        }];
    });
}

- (void)getAssetTypeByIdsWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        NSArray *ids = call.arguments;
        NSMutableArray *resultArr = [NSMutableArray new];
        for (NSString *imgId in ids) {
            PHAsset *asset = self->_idAssetDict[imgId];
            if ([asset isImage]) {
                [resultArr addObject:@"1"];
            } else if ([asset isVideo]) {
                [resultArr addObject:@"2"];
            } else {
                [resultArr addObject:@"0"];
            }
        }
        result(resultArr);
    });
}


- (void)getTimeStampWithIdsWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSArray<NSString *> *ids = call.arguments;
    NSMutableArray<NSNumber *> *r = [NSMutableArray new];
    for (NSString *id in ids) {
        PHAsset *asset = _idAssetDict[id];
        if (asset) {
            [r addObject:@(asset.creationDate.timeIntervalSince1970 * 1000)];
        } else {
            [r addObject:@0];
        }
    }
    result(r);
}

- (void)isCloudWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {

    NSString *imageId = call.arguments;

    PHAsset *asset = _idAssetDict[imageId];
    if (asset) {

    } else {
        result(nil);
    }
}

- (void)getDurationWithId:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *imageId = call.arguments;
    PHAsset *asset = [_idAssetDict valueForKey:imageId];
    int duration = (int) [asset duration];
    if (duration == 0) {
        result(nil);
    } else {
        result([[NSNumber alloc] initWithInt:duration]);
    }
}


- (void)getSizeWithId:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *imageId = call.arguments;
    PHAsset *asset = [_idAssetDict valueForKey:imageId];
    if (!asset) {
        result([NSDictionary new]);
        return;
    }
    NSUInteger width = [asset pixelWidth];
    NSUInteger height = [asset pixelHeight];
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"width"] = @(width);
    dict[@"height"] = @(height);
    result(dict);
}

- (void)assetExistsWithId:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *id = call.arguments;
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[id] options:[PHFetchOptions new]];
    if (fetchResult != nil && fetchResult.count > 0) {
        result(@YES);
    } else {
        result(@NO);
    }
}

+ (NSArray *)convertNSData:(NSData *)data {
    NSMutableArray *array = [NSMutableArray array];
    Byte *bytes = data.bytes;
    for (int i = 0; i < data.length; ++i) {
        [array addObject:@(bytes[i])];
    }
    return array;
}

+ (void)openSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)releaseMemCache:(FlutterMethodCall *)call result:(FlutterResult)result {
    [_galleryArray removeAllObjects];
    [_idCollectionDict removeAllObjects];
    [_idAssetDict removeAllObjects];
    result(@1);
}


#pragma mark - scan for video

- (void)getVideoPathList:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        BOOL isCache = [call.arguments boolValue];
        if (isCache) {
            result(_idVideoArrayDict.allKeys);
            return;
        }

        [self refreshGallery];
        [self refreshGalleryDict:nil];
        if (!_idVideoArrayDict) {
            _idVideoArrayDict = [NSMutableDictionary new];
        }
        [_idVideoArrayDict removeAllObjects];
        [self filterAssetWithBlock:^(PHCollection *collection, PHAsset *asset) {
            if ([collection isKindOfClass:PHAssetCollection.class]) {
                if (!asset.isVideo) {
                    return;
                }
                PHAssetCollection *assetCollection = (PHAssetCollection *) collection;
                NSString *id = assetCollection.localIdentifier;
                if (!_idVideoArrayDict[id]) {
                    _idVideoArrayDict[id] = [NSMutableArray new];
                }
                NSMutableArray *array = _idVideoArrayDict[id];

                [array addObject:asset];
            }
        }];

        NSArray *keys = _idVideoArrayDict.allKeys;
        result(keys);
    });
}

- (void)getAllVideo:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        NSMutableArray<NSString *> *ids = [NSMutableArray new];
        [self filterAssetWithBlock:^(PHCollection *collection, PHAsset *asset) {
            if ([asset isVideo] && ![ids containsObject:asset.localIdentifier]) {
                [ids addObject:asset.localIdentifier];
            }
        }];
//        NSLog(@"video has %d", ids.count);
        result(ids);
    });
}

- (void)getOnlyVideoWithPathId:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *pathId = call.arguments;
    NSMutableArray *ids = [NSMutableArray new];
    NSMutableArray<PHAsset *> *assetArray = _idVideoArrayDict[pathId];

    for (PHAsset *asset in assetArray) {
        [ids addObject:asset.localIdentifier];
    }
    result(ids);
}

#pragma mark - scan for image

- (void)getImagePathList:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        BOOL isCache = [call.arguments boolValue];
        if (isCache) {
            result(_idVideoArrayDict.allKeys);
            return;
        }
        [self refreshGallery];
        [self refreshGalleryDict:nil];
        if (!_idImageArrayDict) {
            _idImageArrayDict = [NSMutableDictionary new];
        }

        [_idImageArrayDict removeAllObjects];
        [self filterAssetWithBlock:^(PHCollection *collection, PHAsset *asset) {
            if ([collection isKindOfClass:PHAssetCollection.class]) {
                if (!asset.isImage) {
                    return;
                }

                PHAssetCollection *assetCollection = (PHAssetCollection *) collection;
                NSString *id = assetCollection.localIdentifier;

                if (!_idImageArrayDict[id]) {
                    _idImageArrayDict[id] = [NSMutableArray new];
                }
                NSMutableArray *array = _idImageArrayDict[id];
                [array addObject:asset];
            }
        }];

        NSArray *keys = _idImageArrayDict.allKeys;
        result(keys);
    });
}

- (void)getAllImage:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        NSMutableArray<NSString *> *ids = [NSMutableArray new];
        [self filterAssetWithBlock:^(PHCollection *collection, PHAsset *asset) {
            if ([asset isImage] && ![ids containsObject:asset.localIdentifier]) {
                [ids addObject:asset.localIdentifier];
            }
        }];
        result(ids);
    });
}

- (void)getOnlyImageWithPathId:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *pathId = call.arguments;
    NSMutableArray *ids = [NSMutableArray new];
    NSMutableArray<PHAsset *> *assetArray = _idImageArrayDict[pathId];

    for (PHAsset *asset in assetArray) {
        [ids addObject:asset.localIdentifier];
    }
    result(ids);
}

# pragma mark - getAssetWithId

- (void)createAssetWithIdWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        NSString *localId = call.arguments;
        PHFetchOptions *options = [PHFetchOptions new];
        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:options];
        if (fetchResult && fetchResult.count != 0) {
            PHAsset *asset = fetchResult[0];
            if (asset) {
                [self handleAsset:asset];
                result(asset.localIdentifier);
            } else {
                result(nil);
            }
        } else {
            result(nil);
        }
    });
}

- (void)handleAsset:(PHAsset *)asset {
    _idAssetDict[asset.localIdentifier] = asset;
}

@end
