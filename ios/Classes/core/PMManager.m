//
// Created by Caijinglong on 2019-09-06.
//


#import "PMManager.h"
#import "PMAssetPathEntity.h"
#import "PHAsset+PHAsset_checkType.h"
#import "PMCacheContainer.h"
#import "ResultHandler.h"
#import "PMLogUtils.h"


@implementation PMManager {
    BOOL __isAuth;
    PMCacheContainer *cacheContainer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __isAuth = NO;
        cacheContainer = [PMCacheContainer new];
    }

    return self;
}


- (BOOL)isAuth {
    return __isAuth;
}

- (void)setAuth:(BOOL)auth {
    __isAuth = auth;
}

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type date:(NSDate *)date hasAll:(BOOL)hasAll {
    NSMutableArray <PMAssetPathEntity *> *array = [NSMutableArray new];

    PHFetchOptions *assetOptions = [self getAssetOptions:type date:date];

    PHFetchOptions *fetchCollectionOptions = [PHFetchOptions new];

    PHFetchResult<PHAssetCollection *> *smartAlbumResult = [PHAssetCollection
            fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                  subtype:PHAssetCollectionSubtypeAlbumRegular
                                  options:fetchCollectionOptions];
    [self injectAssetPathIntoArray:array result:smartAlbumResult options:assetOptions hasAll:hasAll];

    PHFetchResult<PHCollection *> *topLevelResult = [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:fetchCollectionOptions];
    [self injectAssetPathIntoArray:array result:topLevelResult options:assetOptions hasAll:hasAll];

    return array;
}

- (BOOL)existsWithId:(NSString *)assetId {
  PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[ assetId ]
                                                                      options:[PHFetchOptions new]];
  if (!result) {
    return NO;
  }
  return result.count >= 1;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCDFAInspection"

- (void)injectAssetPathIntoArray:(NSMutableArray<PMAssetPathEntity *> *)array
                          result:(PHFetchResult *)result options:(PHFetchOptions *)options
                          hasAll:(BOOL)hasAll {
    for (id collection in result) {
        if (![collection isMemberOfClass:[PHAssetCollection class]]) {
            continue;
        }

        PHAssetCollection *assetCollection = (PHAssetCollection *) collection;

        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];

        PMAssetPathEntity *entity = [PMAssetPathEntity
                entityWithId:assetCollection.localIdentifier
                        name:assetCollection.localizedTitle
                  assetCount:(int) fetchResult.count];

        entity.isAll = assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;

        if (!hasAll && entity.isAll) {
            continue;
        }

        if (entity.assetCount && entity.assetCount > 0) {
            [array addObject:entity];
        }
    }
}

#pragma clang diagnostic pop

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithGalleryId:(NSString *)id type:(int)type page:(NSUInteger)page
                                                    pageCount:(NSUInteger)pageCount date:(NSDate *)date {
    NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

    PHFetchOptions *options = [PHFetchOptions new];

    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id] options:options];
    if (fetchResult && fetchResult.count == 0) {
        return result;
    }

    PHFetchOptions *assetOptions = [self getAssetOptions:type date:date];

    PHAssetCollection *collection = fetchResult.firstObject;

    PHFetchResult<PHAsset *> *assetArray = [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

    if (assetArray.count == 0) {
        return result;
    }

    NSUInteger startIndex = page * pageCount;
    NSUInteger endIndex = startIndex + pageCount - 1;

    NSUInteger count = assetArray.count;
    if (endIndex >= count) {
        endIndex = count - 1;
    }

    for (NSUInteger i = startIndex; i <= endIndex; i++) {
        PHAsset *asset = assetArray[i];
        PMAssetEntity *entity = [self convertPHAssetToAssetEntity:asset];
        [result addObject:entity];
        [cacheContainer putAssetEntity:entity];
    }

    return result;
}

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithRange:(NSString *)id type:(NSUInteger)type start:(NSUInteger)start
                                                      end:(NSUInteger)end date:(NSDate *)date {
    NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

    PHFetchOptions *options = [PHFetchOptions new];

    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id] options:options];
    if (fetchResult && fetchResult.count == 0) {
        return result;
    }

    PHFetchOptions *assetOptions = [self getAssetOptions:(int)type date:date];

    PHAssetCollection *collection = fetchResult.firstObject;
    PHFetchResult<PHAsset *> *assetArray = [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

    if (assetArray.count == 0) {
        return result;
    }

    NSUInteger startIndex = start;
    NSUInteger endIndex = end - 1;

    NSUInteger count = assetArray.count;
    if (endIndex >= count) {
        endIndex = count - 1;
    }

    for (NSUInteger i = startIndex; i <= endIndex; i++) {
        PHAsset *asset = assetArray[i];
        PMAssetEntity *entity = [self convertPHAssetToAssetEntity:asset];
        [result addObject:entity];
        [cacheContainer putAssetEntity:entity];
    }

    return result;
}

- (PMAssetEntity *)convertPHAssetToAssetEntity:(PHAsset *)asset {
    // type:
    // 0: all , 1: image, 2:video

    int type = 0;
    if (asset.isImage) {
        type = 1;
    } else if (asset.isVideo) {
        type = 2;
    }

    NSDate *date = asset.creationDate;
    long createDt = (long) date.timeIntervalSince1970;

    NSDate *modifiedDate = asset.modificationDate;
    long modifiedTimeStamp = (long) modifiedDate.timeIntervalSince1970;

    PMAssetEntity *entity = [PMAssetEntity entityWithId:asset.localIdentifier
                                               createDt:createDt
                                                  width:asset.pixelWidth
                                                 height:asset.pixelHeight
                                               duration:(long) asset.duration
                                                   type:type];
    entity.phAsset = asset;
    entity.modifiedDt = modifiedTimeStamp;
    return entity;
}

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId {
    PMAssetEntity *entity = [cacheContainer getAssetEntity:assetId];
    if (entity) {
        return entity;
    }
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil];
    if (result == nil || result.count == 0) {
        return nil;
    }

    PHAsset *asset = result[0];
    entity = [self convertPHAssetToAssetEntity:asset];
    [cacheContainer putAssetEntity:entity];
    return entity;
}

- (void)clearCache {
    [cacheContainer clearCache];
}

- (void)getThumbWithId:(NSString *)id width:(NSUInteger)width height:(NSUInteger)height
         resultHandler:(ResultHandler *)handler {
    PMAssetEntity *entity = [self getAssetEntity:id];
    if (entity && entity.phAsset) {
        PHAsset *asset = entity.phAsset;
        [self fetchThumb:asset width:width height:height resultHandler:handler];
    } else {
        [handler replyError:@"asset is not found"];
    }
}

- (void)fetchThumb:(PHAsset *)asset width:(NSUInteger)width height:(NSUInteger)height
     resultHandler:(ResultHandler *)handler {

    PHImageManager *manager = PHImageManager.defaultManager;
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    [options setNetworkAccessAllowed:YES];
    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        if (progress == 1.0) {
            [self fetchThumb:asset width:width height:height resultHandler:handler];
        }
    }];
    [manager requestImageForAsset:asset targetSize:CGSizeMake(width, height) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {

        BOOL downloadFinished = [PMManager isDownloadFinish:info];

        if (!downloadFinished) {
            return;
        }

        if ([handler isReplied]) {
            return;
        }

        NSData *imageData = UIImageJPEGRepresentation(result, 0.95);
        FlutterStandardTypedData *data = [FlutterStandardTypedData typedDataWithBytes:imageData];
        [handler reply:data];
    }];
}

- (void)getFullSizeFileWithId:(NSString *)id resultHandler:(ResultHandler *)handler {
    PMAssetEntity *entity = [self getAssetEntity:id];
    if (entity && entity.phAsset) {
        PHAsset *asset = entity.phAsset;
        if (asset.isVideo) {
            [self fetchFullSizeVideo:asset handler:handler];
            return;
        } else {
            [self fetchFullSize:asset resultHandler:handler];
        }
    } else {
        [handler replyError:@"asset is not found"];
    }
}

- (void)fetchFullSizeVideo:(PHAsset *)asset handler:(ResultHandler *)handler {
    NSString *homePath = NSTemporaryDirectory();
    NSFileManager *manager = NSFileManager.defaultManager;

    NSMutableString *path = [NSMutableString stringWithString:homePath];

    NSString *filename = [asset valueForKey:@"filename"];

    NSString *dirPath = [NSString stringWithFormat:@"%@/%@", homePath, @".video"];
    [manager createDirectoryAtPath:dirPath withIntermediateDirectories:true attributes:@{} error:nil];

    [path appendFormat:@"%@/%@", @".video", filename];
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    if ([manager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        [handler reply:path];
        return;
    }

    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        if (progress == 1.0) {
            [self fetchFullSizeVideo:asset handler:handler];
        }
    }];

    [options setNetworkAccessAllowed:YES];

    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix,
            NSDictionary *_Nullable info) {

        BOOL downloadFinish = [PMManager isDownloadFinish:info];

        if (!downloadFinish) {
            return;
        }

        NSString *preset = AVAssetExportPresetHighestQuality;
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:preset];
        if (exportSession) {
            exportSession.outputFileType = AVFileTypeMPEG4;
            exportSession.outputURL = [NSURL fileURLWithPath:path];
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                [handler reply:path];
            }];
        } else {
            [handler reply:nil];
        }

    }];
}

- (void)fetchFullSize:(PHAsset *)asset resultHandler:(ResultHandler *)handler {
    PHImageManager *manager = PHImageManager.defaultManager;
    PHImageRequestOptions *options = [PHImageRequestOptions new];

    // Temp dir image asset
    NSString *homePath = NSTemporaryDirectory();
    NSString *dirPath = [NSString stringWithFormat:@"%@/%@", homePath, @".image"];
    [NSFileManager.defaultManager createDirectoryAtPath:dirPath withIntermediateDirectories:true attributes:@{} error:nil];

    [options setNetworkAccessAllowed:YES];
    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        if (progress == 1.0) {
            [self fetchFullSize:asset resultHandler:handler];
        }
    }];

    [manager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *_Nullable image, NSDictionary *_Nullable info) {

        BOOL downloadFinished = [PMManager isDownloadFinish:info];
        if (!downloadFinished) {
            return;
        }

        if ([handler isReplied]) {
            return;
        }

        NSMutableString *path = [NSMutableString stringWithString:homePath];
        NSString *filename = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/"
                                                                              withString:@"_"];
        [path appendFormat:@"%@/%@.jpg", @".image", filename];
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:YES];

        [handler reply:path];
    }];
}

+ (BOOL)isDownloadFinish:(NSDictionary *)info {
    return ![info[PHImageCancelledKey] boolValue] && !info[PHImageErrorKey] && ![info[PHImageResultIsDegradedKey] boolValue];
}

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id type:(int)type date:(NSDate *)date {
    PHFetchOptions *collectionFetchOptions = [PHFetchOptions new];
    PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id] options:collectionFetchOptions];

    if (result == nil || result.count == 0) {
        return nil;
    }
    PHAssetCollection *collection = result[0];
    PHFetchOptions *assetOptions = [self getAssetOptions:type date:date];
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

    return [PMAssetPathEntity entityWithId:id name:collection.localizedTitle assetCount:(int)fetchResult.count];
}

- (PHFetchOptions *)getAssetOptions:(int)type date:(NSDate *)date {
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];

    if (type == 1) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d AND creationDate <= %@", PHAssetMediaTypeImage, date];
    } else if (type == 2) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d AND creationDate <= %@", PHAssetMediaTypeVideo, date];
    } else {
        options.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d OR mediaType == %d) AND creationDate <= %@", PHAssetMediaTypeImage, PHAssetMediaTypeVideo, date];
    }

    return options;
}

+ (void)openSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {

        }];
    }
}

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block {
    [[PHPhotoLibrary sharedPhotoLibrary]
            performChanges:^{
                PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:ids options:[PHFetchOptions new]];
                [PHAssetChangeRequest deleteAssets:result];
            } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            block(ids);
        } else {
            block(@[]);
        }
    }];
}

- (void)saveImage:(NSData *)data title:(NSString *)title desc:(NSString *)desc block:(AssetResult)block {
    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
            performChanges:^{
                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
                [options setOriginalFilename:title];
                [request addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
                assetId = request.placeholderForCreatedAsset.localIdentifier;
            } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"create asset : id = %@", assetId);
            block([self getAssetEntity:assetId]);
        } else {
            NSLog(@"create fail");
            block(nil);
        }
    }];
}

- (void)saveVideo:(NSString *)path title:(NSString *)title desc:(NSString *)desc block:(AssetResult)block {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
            performChanges:^{
                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
                PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
                [options setOriginalFilename:title];
                [request addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:options];
                assetId = request.placeholderForCreatedAsset.localIdentifier;
            } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"create asset : id = %@", assetId);
            block([self getAssetEntity:assetId]);
        } else {
            NSLog(@"create fail");
            block(nil);
        }
    }];
}

@end
