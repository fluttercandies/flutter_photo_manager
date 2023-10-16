#import "NSString+PM_COMMON.h"
#import "PHAsset+PM_COMMON.h"
#import "PHAssetCollection+PM_COMMON.h"
#import "PHAssetResource+PM_COMMON.h"
#import "PMAssetPathEntity.h"
#import "PMCacheContainer.h"
#import "PMConvertUtils.h"
#import "PMFolderUtils.h"
#import "PMImageUtil.h"
#import "PMManager.h"
#import "PMMD5Utils.h"
#import "PMPathFilterOption.h"

@implementation PMManager {
    PMCacheContainer *cacheContainer;

    PHCachingImageManager *__cachingManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        cacheContainer = [PMCacheContainer new];
    }
    return self;
}

- (PHCachingImageManager *)cachingManager {
    if (__cachingManager == nil) {
        __cachingManager = [PHCachingImageManager new];
    }

    return __cachingManager;
}

- (NSArray<PMAssetPathEntity *> *)getAssetPathList:(int)type hasAll:(BOOL)hasAll onlyAll:(BOOL)onlyAll option:(NSObject <PMBaseFilter> *)option pathFilterOption:(PMPathFilterOption *)pathFilterOption {
    NSMutableArray<PMAssetPathEntity *> *array = [NSMutableArray new];
    PHFetchOptions *assetOptions = [self getAssetOptions:type filterOption:option];
    PHFetchOptions *fetchCollectionOptions = [PHFetchOptions new];

    PHFetchResult<PHAssetCollection *> *smartAlbumResult = [PHAssetCollection
        fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                              subtype:PHAssetCollectionSubtypeAny
                              options:fetchCollectionOptions];
    if (onlyAll) {
        if (smartAlbumResult && smartAlbumResult.count) {
            for (PHAssetCollection *collection in smartAlbumResult) {
                if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                    PMAssetPathEntity *pathEntity = [PMAssetPathEntity
                        entityWithId:collection.localIdentifier
                                name:collection.localizedTitle
                     assetCollection:collection
                    ];
                    pathEntity.isAll = YES;
                    [array addObject:pathEntity];
                    break;
                }
            }
        }
        return array;
    }

    if ([pathFilterOption.type indexOfObject:@(PHAssetCollectionTypeSmartAlbum)] != NSNotFound) {
        [self logCollections:smartAlbumResult option:assetOptions];
        [self injectAssetPathIntoArray:array
                                result:smartAlbumResult
                               options:assetOptions
                                hasAll:hasAll
                      containsModified:option.containsModified
                      pathFilterOption:pathFilterOption
        ];
    }

    if ([pathFilterOption.type indexOfObject:@(PHAssetCollectionTypeAlbum)] != NSNotFound) {
        PHFetchResult<PHAssetCollection *> *albumResult = [PHAssetCollection
            fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                  subtype:PHAssetCollectionSubtypeAny
                                  options:fetchCollectionOptions];
        [self logCollections:albumResult option:assetOptions];
        [self injectAssetPathIntoArray:array
                                result:albumResult
                               options:assetOptions
                                hasAll:hasAll
                      containsModified:option.containsModified
                      pathFilterOption:pathFilterOption];
    }
    return array;
}

- (NSUInteger)getAssetCountFromPath:(NSString *)id type:(int)type filterOption:(NSObject<PMBaseFilter> *)filterOption {
    PHFetchOptions *assetOptions = [self getAssetOptions:type filterOption:filterOption];
    PHFetchOptions *fetchCollectionOptions = [PHFetchOptions new];
    PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection
                                                  fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                                  options:fetchCollectionOptions];

    if (result == nil || result.count == 0) {
        return 0;
    }
    PHAssetCollection *collection = result[0];
    NSUInteger count = [collection obtainAssetCount:assetOptions];
    return count;
}

- (void)logCollections:(PHFetchResult *)collections option:(PHFetchOptions *)option {
    if(!PMLogUtils.sharedInstance.isLog){
        return;
    }
    for (PHCollection *phCollection in collections) {
        if ([phCollection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *collection = (PHAssetCollection *) phCollection;
            PHFetchResult<PHAsset *> *result = [PHAsset fetchKeyAssetsInAssetCollection:collection options:option];
            NSLog(@"collection name = %@, count = %lu", collection.localizedTitle, (unsigned long)result.count);
        } else {
            NSLog(@"collection name = %@", phCollection.localizedTitle);
        }
    }
}

- (NSUInteger)getAssetCountWithType:(int)type option:(NSObject<PMBaseFilter> *)filter {
    PHFetchOptions *options = [filter getFetchOptions:type];
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithOptions:options];
    return result.count;
}

- (NSArray<PMAssetEntity *> *)getAssetsWithType:(int)type option:(NSObject<PMBaseFilter> *)option start:(int)start end:(int)end {
    PHFetchOptions *options = [option getFetchOptions:type];
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithOptions:options];
    
    NSUInteger endOffset = end;
    if (endOffset > result.count) {
        endOffset = result.count;
    }
    
    NSMutableArray<PMAssetEntity*>* array = [NSMutableArray new];
    
    for (NSUInteger i = start; i < endOffset; i++){
        if (i >= result.count) {
            break;
        }
        PHAsset *asset = result[i];
        PMAssetEntity *pmAsset = [self convertPHAssetToAssetEntity:asset needTitle:[option needTitle]];
        [array addObject: pmAsset];
    }
    
    return array;
}

- (BOOL)existsWithId:(NSString *)assetId {
    PHFetchResult<PHAsset *> *result =
    [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:[PHFetchOptions new]];
    return result && result.count > 0;
}

- (BOOL)entityIsLocallyAvailable:(NSString *)assetId resource:(PHAssetResource *)resource isOrigin:(BOOL)isOrigin {
    PHFetchResult<PHAsset *> *result =
    [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:[PHFetchOptions new]];
    if (!result) {
        return NO;
    }
    PHAsset *asset = result.firstObject;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset resource:nil isOrigin:isOrigin manager:fileManager];
    BOOL isExist = [fileManager fileExistsAtPath:path];
    [[PMLogUtils sharedInstance] info:[NSString
                                       stringWithFormat:@"Locally available for path %@: %hhd",
                                       path, isExist]];
    if (isExist) {
        return YES;
    }
    NSArray *rArray = [PHAssetResource assetResourcesForAsset:asset];
    // If this returns NO, then the asset is in iCloud or not saved locally yet.
    return [[rArray.firstObject valueForKey:@"locallyAvailable"] boolValue];
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCDFAInspection"

- (void)injectAssetPathIntoArray:(NSMutableArray<PMAssetPathEntity *> *)array
                          result:(PHFetchResult *)result
                         options:(PHFetchOptions *)options
                          hasAll:(BOOL)hasAll
                containsModified:(BOOL)containsModified
                pathFilterOption:(PMPathFilterOption *)pathFilterOption {
    for (id collection in result) {
        if (![collection isKindOfClass:[PHAssetCollection class]]) {
            continue;
        }

        PHAssetCollection *assetCollection = (PHAssetCollection *) collection;

//        // Check whether it's "Recently Deleted"
//        if (assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded
//            || assetCollection.assetCollectionSubtype == 1000000201) {
//            continue;
//        }

        // Check nullable id and name
        NSString *localIdentifier = assetCollection.localIdentifier;
        NSString *localizedTitle = assetCollection.localizedTitle;
        if (!localIdentifier || localIdentifier.isEmpty || !localizedTitle || localizedTitle.isEmpty) {
            continue;
        }

//        [[PMLogUtils sharedInstance] debug:[NSString stringWithFormat:@"id: %@, title: %@, type: %d subType: %d", localIdentifier, localizedTitle, (int)assetCollection.assetCollectionType, (int)assetCollection.assetCollectionSubtype]];

        PMAssetPathEntity *entity = [PMAssetPathEntity entityWithId:localIdentifier name:localizedTitle assetCollection:assetCollection];
        entity.isAll = assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;

        if (containsModified) {
            PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            entity.assetCount = fetchResult.count;
            if (fetchResult.count > 0) {
                PHAsset *asset = fetchResult.firstObject;
                entity.modifiedDate = (long) asset.modificationDate.timeIntervalSince1970;
            }
        }

        if (hasAll && entity.isAll) {
            [array addObject:entity];
            continue;
        }

        if ([pathFilterOption.subType indexOfObject:@(PHAssetCollectionSubtypeAny)] != NSNotFound ||
            [pathFilterOption.subType indexOfObject:@(assetCollection.assetCollectionSubtype)] != NSNotFound) {
            [array addObject:entity];
        }
    }
}

#pragma clang diagnostic pop

- (NSArray<PMAssetEntity *> *)getAssetListPaged:(NSString *)id type:(int)type page:(NSUInteger)page size:(NSUInteger)size filterOption:(NSObject<PMBaseFilter> *)filterOption {
    NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

    PHFetchOptions *options = [PHFetchOptions new];

    PHFetchResult<PHAssetCollection *> *fetchResult =
    [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                                         options:options];
    if (fetchResult && fetchResult.count == 0) {
        return result;
    }

    PHAssetCollection *collection = fetchResult.firstObject;
    PHFetchOptions *assetOptions = [self getAssetOptions:type filterOption:filterOption];
    PHFetchResult<PHAsset *> *assetArray = [PHAsset fetchAssetsInAssetCollection:collection
                                                                         options:assetOptions];

    if (assetArray.count == 0) {
        return result;
    }

    NSUInteger startIndex = page * size;
    NSUInteger endIndex = startIndex + size - 1;

    NSUInteger count = assetArray.count;
    if (endIndex >= count) {
        endIndex = count - 1;
    }

    BOOL imageNeedTitle = filterOption.needTitle;
    BOOL videoNeedTitle = filterOption.needTitle;

    for (NSUInteger i = startIndex; i <= endIndex; i++) {
        NSUInteger index = i;
        if (assetOptions.sortDescriptors == nil) {
            index = count - i - 1;
        }
        PHAsset *asset = assetArray[index];
        BOOL needTitle = NO;
        if ([asset isVideo]) {
            needTitle = videoNeedTitle;
        } else if ([asset isImage]) {
            needTitle = imageNeedTitle;
        }
        PMAssetEntity *entity = [self convertPHAssetToAssetEntity:asset needTitle:needTitle];
        [result addObject:entity];
        [cacheContainer putAssetEntity:entity];
    }

    return result;
}

- (NSArray<PMAssetEntity *> *)getAssetListRange:(NSString *)id type:(int)type start:(NSUInteger)start end:(NSUInteger)end filterOption:(NSObject<PMBaseFilter> *)filterOption {
    NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

    PHFetchOptions *options = [PHFetchOptions new];

    PHFetchResult<PHAssetCollection *> *fetchResult =
    [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                                         options:options];
    if (fetchResult && fetchResult.count == 0) {
        return result;
    }

    PHAssetCollection *collection = fetchResult.firstObject;
    PHFetchOptions *assetOptions = [self getAssetOptions:(int) type filterOption:filterOption];
    PHFetchResult<PHAsset *> *assetArray = [PHAsset fetchAssetsInAssetCollection:collection
                                                                         options:assetOptions];

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
        NSUInteger index = i;
        if (assetOptions.sortDescriptors == nil) {
            index = count - i - 1;
        }
        PHAsset *asset = assetArray[index];
        BOOL needTitle;
        if ([asset isVideo]) {
            needTitle = filterOption.needTitle;
        } else if ([asset isImage]) {
            needTitle = filterOption.needTitle;
        } else {
            needTitle = NO;
        }

        PMAssetEntity *entity = [self convertPHAssetToAssetEntity:asset needTitle:needTitle];
        [result addObject:entity];
        [cacheContainer putAssetEntity:entity];
    }

    return result;
}

- (PMAssetEntity *)convertPHAssetToAssetEntity:(PHAsset *)asset
                                     needTitle:(BOOL)needTitle {
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
    entity.lat = asset.location.coordinate.latitude;
    entity.lng = asset.location.coordinate.longitude;
    entity.title = needTitle ? [asset title] : @"";
    entity.favorite = asset.isFavorite;
    entity.subtype = asset.mediaSubtypes;

    return entity;
}

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId {
    return [self getAssetEntity:assetId withCache:YES];
}

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId withCache:(BOOL)withCache {
    PMAssetEntity *entity;
    if (withCache) {
        entity = [cacheContainer getAssetEntity:assetId];
        if (entity) {
            return entity;
        }
    }
    PHFetchResult<PHAsset *> *result =
    [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil];
    if (result == nil || result.count == 0) {
        return nil;
    }

    PHAsset *asset = result[0];
    entity = [self convertPHAssetToAssetEntity:asset needTitle:NO];
    [cacheContainer putAssetEntity:entity];
    return entity;
}

- (void)clearCache {
    [cacheContainer clearCache];
}

- (void)getThumbWithId:(NSString *)id option:(PMThumbLoadOption *)option resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PMAssetEntity *entity = [self getAssetEntity:id];
    if (entity && entity.phAsset) {
        PHAsset *asset = entity.phAsset;
        [self fetchThumb:asset option:option resultHandler:handler progressHandler:progressHandler];
    } else {
        [handler replyError:@"asset is not found"];
    }
}

- (void)fetchThumb:(PHAsset *)asset option:(PMThumbLoadOption *)option resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHImageManager *manager = PHImageManager.defaultManager;
    PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
    requestOptions.deliveryMode = option.deliveryMode;
    requestOptions.resizeMode = option.resizeMode;

    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];

    [requestOptions setNetworkAccessAllowed:YES];
    [requestOptions setProgressHandler:^(double progress, NSError *error, BOOL *stop,
                                         NSDictionary *info) {
        if (error) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            [progressHandler deinit];
            return;
        }
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    int width = option.width;
    int height = option.height;

    [manager requestImageForAsset:asset
                       targetSize:CGSizeMake(width, height)
                      contentMode:option.contentMode
                          options:requestOptions
                    resultHandler:^(PMImage *result, NSDictionary *info) {
        BOOL downloadFinished = [PMManager isDownloadFinish:info];

        if (!downloadFinished) {
            return;
        }

        if ([handler isReplied]) {
            return;
        }
        NSData *imageData = [PMImageUtil convertToData:result formatType:option.format quality:option.quality];
        if (imageData) {
            id data = [self.converter convertData:imageData];
            [handler reply:data];
        } else {
            [handler reply: nil];
        }

        [self notifySuccess:progressHandler];

    }];

}

- (void)getFullSizeFileWithId:(NSString *)id isOrigin:(BOOL)isOrigin subtype:(int)subtype resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PMAssetEntity *entity = [self getAssetEntity:id];
    if (entity && entity.phAsset) {
        PHAsset *asset = entity.phAsset;
        if (@available(iOS 9.1, *)) {
            if (asset.isLivePhoto && (subtype & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
                [self fetchLivePhotosFile:asset handler:handler progressHandler:progressHandler];
                return;
            }
        }
        if (@available(macOS 14.0, *)) {
            if (asset.isLivePhoto && (subtype & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
                [self fetchLivePhotosFile:asset handler:handler progressHandler:progressHandler];
                return;
            }
        }
        if (asset.isVideo) {
            if (isOrigin) {
                [self fetchOriginVideoFile:asset handler:handler progressHandler:progressHandler];
            } else {
                [self fetchFullSizeVideo:asset handler:handler progressHandler:progressHandler withScheme:NO];
            }
            return;
        }
        if (isOrigin) {
            [self fetchOriginImageFile:asset resultHandler:handler progressHandler:progressHandler];
        } else {
            [self fetchFullSizeImageFile:asset resultHandler:handler progressHandler:progressHandler];
        }
        return;
    }
    [handler replyError:@"Asset file cannot be obtained."];
}

- (void)fetchLivePhotosFile:(PHAsset *)asset handler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHAssetResource *resource = [asset getLivePhotosResource];
    if (!resource) {
        [handler reply:nil];
        return;
    }
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset resource:resource isOrigin:YES manager:fileManager];
    if ([fileManager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        [handler reply:path];
        return;
    }

    PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
    [options setNetworkAccessAllowed:YES];

    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress) {
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];

    PHAssetResourceManager *resourceManager = PHAssetResourceManager.defaultManager;
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    [resourceManager writeDataForAssetResource:resource
                                        toFile:fileUrl
                                       options:options
                             completionHandler:^(NSError *_Nullable error) {
        if (error) {
            NSLog(@"error = %@", error);
            [self notifyProgress:progressHandler progress:0 state:PMProgressStateFailed];
            [handler reply:nil];
        } else {
            [handler reply:path];
            [self notifySuccess:progressHandler];
        }
    }];
}

- (void)fetchOriginVideoFile:(PHAsset *)asset handler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHAssetResource *resource = [asset getAdjustResource];
    if (!resource) {
        [handler reply:nil];
        return;
    }
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset resource:resource isOrigin:YES manager:fileManager];
    if ([fileManager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        [handler reply:path];
        return;
    }

    PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
    [options setNetworkAccessAllowed:YES];

    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress) {
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];

    PHAssetResourceManager *resourceManager = PHAssetResourceManager.defaultManager;
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    [resourceManager writeDataForAssetResource:resource
                                        toFile:fileUrl
                                       options:options
                             completionHandler:^(NSError *_Nullable error) {
        if (error) {
            NSLog(@"error = %@", error);
            [self notifyProgress:progressHandler progress:0 state:PMProgressStateFailed];
            [handler reply:nil];
        } else {
            [handler reply:path];
            [self notifySuccess:progressHandler];
        }
    }];
}

- (void)fetchFullSizeVideo:(PHAsset *)asset
                   handler:(NSObject <PMResultHandler> *)handler
           progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                withScheme:(BOOL)withScheme {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset resource:nil isOrigin:NO manager:manager];
    if ([manager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Read cache from %@", path]];
        if (withScheme) {
            [handler reply:[NSURL fileURLWithPath:path].absoluteString];
        } else {
            [handler reply:path];
        }
        return;
    }

    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    [options setDeliveryMode:PHVideoRequestOptionsDeliveryModeAutomatic];
    [options setNetworkAccessAllowed:YES];
    [options setVersion:PHVideoRequestOptionsVersionCurrent];
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        if (error) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            [progressHandler deinit];
            return;
        }
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];

    [[PHImageManager defaultManager]
     requestAVAssetForVideo:asset
     options:options
     resultHandler:^(AVAsset *_Nullable asset,
                     AVAudioMix *_Nullable audioMix,
                     NSDictionary *_Nullable info) {
        BOOL downloadFinish = [PMManager isDownloadFinish:info];
        if (!downloadFinish) {
            return;
        }

        NSURL *destination = [NSURL fileURLWithPath:path];
        // Check whether the asset is already an `AVURLAsset`,
        // then copy the asset file into the sandbox instead of export.
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *) asset;
            NSURL *videoURL = urlAsset.URL;
            if ([[videoURL path] isEqualToString:[destination path]]) {
                if (withScheme) {
                    [handler reply:videoURL.absoluteString];
                } else {
                    [handler reply:[videoURL path]];
                }
                return;
            }
            NSError *error;
            NSString *destinationPath = destination.path;
            if ([manager fileExistsAtPath:destinationPath]) {
                [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Reading cache from %@", destinationPath]];
                if (withScheme) {
                    [handler reply:destination.absoluteString];
                } else {
                    [handler reply:destinationPath];
                }
                return;
            }
            [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Caching the video to %@", destination]];
            [[NSFileManager defaultManager] copyItemAtURL:videoURL
                                                    toURL:destination
                                                    error:&error];
            if (error) {
                [handler replyError:[NSString stringWithFormat:@"Could not cache the video file: %@", error]];
                return;
            }
            if (withScheme) {
                [handler reply:destination.absoluteString];
            } else {
                [handler reply:path];
            }
            return;
        }

        // Export the asset eventually, typically for `AVComposition`s.
        AVAssetExportSession *exportSession = [AVAssetExportSession
                                               exportSessionWithAsset:asset
                                               presetName:AVAssetExportPresetHighestQuality];
        if (exportSession) {
            NSString *extension = [[path pathExtension] lowercaseString];
            // Determine the output type for the fastest speed.
            AVFileType outputFileType;
            if ([extension isEqualToString:@"mov"]) {
                outputFileType = AVFileTypeQuickTimeMovie;
            } else if ([extension isEqualToString:@"m4v"]) {
                outputFileType = AVFileTypeAppleM4V;
            } else {
                outputFileType = AVFileTypeMPEG4;
            }
            exportSession.outputFileType = outputFileType;
            exportSession.outputURL = destination;
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                    if (withScheme) {
                        [handler reply:destination.absoluteString];
                    } else {
                        [handler reply:path];
                    }
                    [self notifySuccess:progressHandler];
                } else if (exportSession.status == AVAssetExportSessionStatusFailed ||
                           exportSession.status == AVAssetExportSessionStatusCancelled) {
                    [self notifyProgress:progressHandler progress:1.0 state:PMProgressStateFailed];
                    [progressHandler deinit];
                    [handler replyError:[NSString stringWithFormat:@"%@", exportSession.error]];
                }
            }];
            return;
        }
        [handler replyError:@"Unable to initialize an export session."];
    }];
}

- (NSString *)makeAssetOutputPath:(PHAsset *)asset
                         resource:(PHAssetResource *)resource
                         isOrigin:(Boolean)isOrigin
                          manager:(NSFileManager *)manager {
    NSString *id = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *modifiedDate = [NSString stringWithFormat:@"%f", asset.modificationDate.timeIntervalSince1970];
    NSString *homePath = NSTemporaryDirectory();
    NSMutableString *path = [NSMutableString stringWithString:homePath];
    NSString *filename;
    if (resource) {
        filename = resource.originalFilename;
    } else {
        filename = [asset valueForKey:@"filename"];
    }
    filename = [NSString stringWithFormat:@"%@_%@%@_%@", id, modifiedDate, isOrigin ? @"_o" : @"", filename];
    NSString *typeDirPath;
    if (resource) {
        typeDirPath = resource.isImage ? PM_IMAGE_CACHE_PATH : PM_VIDEO_CACHE_PATH;
    } else {
        typeDirPath = asset.isImage ? PM_IMAGE_CACHE_PATH : PM_VIDEO_CACHE_PATH;
    }
    NSString *dirPath = [NSString stringWithFormat:@"%@%@", homePath, typeDirPath];
    if (manager == nil) {
        manager = NSFileManager.defaultManager;
    }
    [manager createDirectoryAtPath:dirPath withIntermediateDirectories:true attributes:@{} error:nil];
    [path appendFormat:@"%@/%@", typeDirPath, filename];
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"PHAsset path = %@", path]];
    return path;
}

- (NSString *)writeFullFileWithAssetId:(PHAsset *)asset imageData:(NSData *)imageData {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSMutableString *path = [NSMutableString stringWithString:[self getCachePath:PM_FULL_IMAGE_CACHE_PATH]];
    NSError *error;
    [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{} error:&error];
    [path appendString:@"/"];
    [path appendString:[PMMD5Utils getMD5FromString:asset.localIdentifier]];
    [path appendString:@"_exif"];
    [path appendString:@".jpg"];
    [manager createFileAtPath:path contents:imageData attributes:@{}];
    return path;
}

- (BOOL)isImage:(PHAssetResource *)resource {
    return resource.type == PHAssetResourceTypePhoto || resource.type == PHAssetResourceTypeFullSizePhoto;
}

- (void)fetchOriginImageFile:(PHAsset *)asset resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHAssetResource *imageResource = [asset getAdjustResource];
    if (!imageResource) {
        [handler reply:nil];
        return;
    }
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset
                                      resource:imageResource
                                      isOrigin:YES
                                       manager:fileManager];
    if ([fileManager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        [handler reply:path];
        return;
    }

    PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
    [options setNetworkAccessAllowed:YES];
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress) {
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];

    PHAssetResourceManager *resourceManager = PHAssetResourceManager.defaultManager;
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    [resourceManager writeDataForAssetResource:imageResource
                                        toFile:fileUrl
                                       options:options
                             completionHandler:^(NSError *_Nullable error) {
        if (error) {
            NSLog(@"error = %@", error);
            [handler reply:nil];
        } else {
            [handler reply:path];
            [self notifySuccess:progressHandler];
        }
    }];
}

- (void)fetchFullSizeImageFile:(PHAsset *)asset resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHImageManager *manager = PHImageManager.defaultManager;

    PHImageRequestOptions *options = [PHImageRequestOptions new];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeOpportunistic];
    [options setNetworkAccessAllowed:YES];
    [options setResizeMode:PHImageRequestOptionsResizeModeNone];
    [options setSynchronous:YES];
    [options setVersion:PHImageRequestOptionsVersionCurrent];
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop,
                                  NSDictionary *info) {
        if (error) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            [progressHandler deinit];
            return;
        }
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];

    [manager requestImageForAsset:asset
                       targetSize:PHImageManagerMaximumSize
                      contentMode:PHImageContentModeDefault
                          options:options
                    resultHandler:^(PMImage *_Nullable image,
                                    NSDictionary *_Nullable info) {

        BOOL downloadFinished = [PMManager isDownloadFinish:info];
        if (!downloadFinished) {
            return;
        }

        if ([handler isReplied]) {
            return;
        }

        NSData *data = [PMImageUtil convertToData:image formatType:PMThumbFormatTypeJPEG quality:1.0];

        if (data) {
            NSString *path = [self writeFullFileWithAssetId:asset imageData: data];
            [handler reply:path];
        } else {
            [handler reply:nil];
        }

        [self notifySuccess:progressHandler];
    }];
}

+ (BOOL)isDownloadFinish:(NSDictionary *)info {
    return ![info[PHImageCancelledKey] boolValue] &&      // No cancel.
    !info[PHImageErrorKey] &&                      // Error.
    ![info[PHImageResultIsDegradedKey] boolValue]; // thumbnail
}

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id type:(int)type filterOption:(NSObject <PMBaseFilter> *)filterOption {
    PHFetchOptions *collectionFetchOptions = [PHFetchOptions new];
    PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection
        fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                          options:collectionFetchOptions];

    if (result == nil || result.count == 0) {
        return nil;
    }
    PHAssetCollection *collection = result[0];

    // Check nullable id and name
    NSString *localIdentifier = collection.localIdentifier;
    NSString *localizedTitle = collection.localizedTitle;
    if (!localIdentifier || localIdentifier.isEmpty || !localizedTitle || localizedTitle.isEmpty) {
        return nil;
    }
    PMAssetPathEntity *entity = [PMAssetPathEntity entityWithId:localIdentifier
                                                           name:localizedTitle
                                                assetCollection:collection
    ];
    entity.isAll = collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    return entity;
}

- (PHFetchOptions *)getAssetOptions:(int)type filterOption:(NSObject<PMBaseFilter> *)optionGroup {
    return [optionGroup getFetchOptions:type];
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

#if TARGET_OS_OSX

+ (void)openSetting:(NSObject<PMResultHandler>*)result {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c" , @"open x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"];
    [task launch];
    [result reply:@true];
}

#endif

#if TARGET_OS_IOS

+ (void)openSetting:(NSObject<PMResultHandler>*)result {
    if (@available(iOS 10, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                           options:[[NSDictionary alloc] init]
                                 completionHandler:^(BOOL success) {
            [result reply: @(success)];
        }];
    } else if (@available(iOS 8.0, *)) {
        BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        [result reply: @(success)];
    } else {
        [result reply: @false];
    }
}

#endif

#pragma clang diagnostic pop

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block {
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHFetchResult<PHAsset *> *result =
        [PHAsset fetchAssetsWithLocalIdentifiers:ids
                                         options:[PHFetchOptions new]];
        [PHAssetChangeRequest deleteAssets:result];
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            block(ids);
        } else {
            block(@[]);
        }
    }];
}

- (void)saveImage:(NSData *)data
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block {
    __block NSString *assetId = nil;
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"save image with data, length: %lu, title:%@, desc: %@", (unsigned long)data.length, title, desc]];

    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request =
        [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options =
        [PHAssetResourceCreationOptions new];
        [options setOriginalFilename:title];
        [request addResourceWithType:PHAssetResourceTypePhoto
                                data:data
                             options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
            block([self getAssetEntity:assetId]);
        } else {
            NSLog(@"create fail");
            block(nil);
        }
    }];
}

- (void)saveImageWithPath:(NSString *)path title:(NSString *)title desc:(NSString *)desc block:(void (^)(PMAssetEntity *))block {
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"save image with path: %@ title:%@, desc: %@", path, title, desc]];

    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request =
        [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options =
        [PHAssetResourceCreationOptions new];
        [options setOriginalFilename:title];
        NSData *data = [NSData dataWithContentsOfFile:path];
        [request addResourceWithType:PHAssetResourceTypePhoto
                                data:data
                             options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
            block([self getAssetEntity:assetId]);
        } else {
            NSLog(@"create fail");
            block(nil);
        }
    }];
}

- (void)saveVideo:(NSString *)path
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block {
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"save video with path: %@, title: %@, desc %@",
                                     path, title, desc]];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        [options setOriginalFilename:title];
        [request addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
            block([self getAssetEntity:assetId]);
        } else {
            NSLog(@"create fail, error: %@", error);
            block(nil);
        }
    }];
}

- (void)saveLivePhoto:(NSString *)imagePath
            videoPath:(NSString *)videoPath
            title:(NSString *)title
            desc:(NSString *)desc
            block:(AssetResult)block {
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"save LivePhoto with imagePath: %@, videoPath: %@, title: %@, desc %@",
                                     imagePath, videoPath, title, desc]];
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    NSURL *imageURL = [NSURL fileURLWithPath:imagePath];
    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        [options setOriginalFilename:title];
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:options];
        [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:videoURL options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
            block([self getAssetEntity:assetId]);
        } else {
            NSLog(@"create fail, error: %@", error);
            block(nil);
        }
    }];
}

- (NSString *)getTitleAsyncWithAssetId:(NSString *)assetId subtype:(int)subtype {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
    if (asset) {
        return [asset originalFilenameWithSubtype:subtype];
    }
    return @"";
}

- (NSString *)getMimeTypeAsyncWithAssetId:(NSString *)assetId {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (asset) {
        return [asset mimeType];
    }
    return nil;
}

- (void)getMediaUrl:(NSString *)assetId resultHandler:(NSObject <PMResultHandler> *)handler {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
    PHAssetResource *resource;
    if (@available(iOS 9.1, *)) {
        if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
            resource = [asset getLivePhotosResource];
            NSURL *url = [resource valueForKey:@"privateFileURL"];
            [handler reply:url.absoluteString];
            return;
        }
    }
    BOOL isLocallyAvailable = [self entityIsLocallyAvailable:assetId resource:resource isOrigin:NO];
    if (!isLocallyAvailable) {
        [handler replyError:@"Media url is unavailable when the asset is not locally available."];
        return;
    }
    if (asset.isVideo) {
        [self fetchFullSizeVideo:asset handler:handler progressHandler:nil withScheme:YES];
    } else {
        [handler replyError:@"Only video type of assets can get a media url."];
    }
}

- (NSArray<PMAssetPathEntity *> *)getSubPathWithId:(NSString *)id type:(int)type albumType:(int)albumType option:(NSObject<PMBaseFilter> *)option {
    PHFetchOptions *options = [self getAssetOptions:type filterOption:option];

    if ([PMFolderUtils isRecentCollection:id]) {
        NSArray<PHCollectionList *> *array = [PMFolderUtils getRootFolderWithOptions:nil];
        return [self convertPHCollectionToPMAssetPathArray:array option:options];
    }

    if (albumType == PM_TYPE_ALBUM) {
        return @[];
    }

    PHCollectionList *list;

    PHFetchResult<PHCollectionList *> *collectionList = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
    if (collectionList && collectionList.count > 0) {
        list = collectionList.firstObject;
    }

    if (!list) {
        return @[];
    }

    NSArray<PHCollection *> *phCollectionArray = [PMFolderUtils getSubCollectionWithCollection:list options:options];
    return [self convertPHCollectionToPMAssetPathArray:phCollectionArray option:options];
}

- (NSArray<PMAssetPathEntity *> *)convertPHCollectionToPMAssetPathArray:(NSArray<PHCollection *> *)phArray
                                                                 option:(PHFetchOptions *)option {
    NSMutableArray<PMAssetPathEntity *> *result = [NSMutableArray new];

    for (PHCollection *collection in phArray) {
        [result addObject:[self convertPHCollectionToPMPath:collection option:option]];
    }

    return result;
}

- (PMAssetPathEntity *)convertPHCollectionToPMPath:(PHCollection *)phCollection option:(PHFetchOptions *)option {
    PMAssetPathEntity *pathEntity = [PMAssetPathEntity new];

    pathEntity.id = phCollection.localIdentifier;
    pathEntity.isAll = NO;
    pathEntity.name = phCollection.localizedTitle;
    if ([phCollection isMemberOfClass:PHAssetCollection.class]) {
        pathEntity.type = PM_TYPE_ALBUM;
    } else {
        pathEntity.type = PM_TYPE_FOLDER;
    }

    return pathEntity;
}

- (PHAssetCollection *)getCollectionWithId:(NSString *)galleryId {
    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[galleryId] options:nil];

    if (fetchResult && fetchResult.count > 0) {
        return fetchResult.firstObject;
    }
    return nil;
}

- (void)copyAssetWithId:(NSString *)id toGallery:(NSString *)gallery block:(void (^)(PMAssetEntity *entity, NSString *msg))block {
    PMAssetEntity *assetEntity = [self getAssetEntity:id];

    if (!assetEntity) {
        NSString *msg = [NSString stringWithFormat:@"not found asset : %@", id];
        block(nil, msg);
        return;
    }

    __block PHAssetCollection *collection = [self getCollectionWithId:gallery];

    if (!collection) {
        NSString *msg = [NSString stringWithFormat:@"not found collection with gallery id : %@", gallery];
        block(nil, msg);
        return;
    }

    if (![collection canPerformEditOperation:PHCollectionEditOperationAddContent]) {
        block(nil, @"The collection can't add from user. The [collection canPerformEditOperation:PHCollectionEditOperationAddContent] return NO!");
        return;
    }

    __block PHFetchResult<PHAsset *> *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[id] options:nil];
    NSError *error;

    [PHPhotoLibrary.sharedPhotoLibrary
     performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        [request addAssets:asset];

    } error:&error];

    if (error) {
        NSString *msg = [NSString stringWithFormat:@"Can't copy, error : %@ ", error];
        block(nil, msg);
        return;
    }

    block(assetEntity, nil);
}

- (void)createFolderWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *, NSString *))block {
    __block NSString *targetId;
    NSError *error;
    if (id) { // create in folder
        PHFetchResult<PHCollectionList *> *result = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
        if (result && result.count > 0) {
            PHCollectionList *parent = result.firstObject;

            [PHPhotoLibrary.sharedPhotoLibrary
             performChangesAndWait:^{
                PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest creationRequestForCollectionListWithTitle:name];
                targetId = request.placeholderForCreatedCollectionList.localIdentifier;
            } error:&error];

            if (error) {
                NSLog(@"createFolderWithName 1: error : %@", error);
            }

            [PHPhotoLibrary.sharedPhotoLibrary
             performChangesAndWait:^{
                PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest changeRequestForCollectionList:parent];
                PHFetchResult<PHCollectionList *> *fetchResult = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[targetId] options:nil];
                [request addChildCollections:fetchResult];
            } error:&error];


            if (error) {
                NSLog(@"createFolderWithName 2: error : %@", error);
            }


            block(targetId, error.localizedDescription);

        } else {
            block(nil, [NSString stringWithFormat:@"Cannot find folder : %@", id]);
            return;
        }
    } else { // create in top
        [PHPhotoLibrary.sharedPhotoLibrary
         performChangesAndWait:^{
            PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest creationRequestForCollectionListWithTitle:name];
            targetId = request.placeholderForCreatedCollectionList.localIdentifier;
        } error:&error];

        if (error) {
            NSLog(@"createFolderWithName 3: error : %@", error);
        }
        block(targetId, error.localizedDescription);
    }

}

- (void)createAlbumWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *, NSString *))block {
    __block NSString *targetId;
    NSError *error;
    if (id) { // create in folder
        PHFetchResult<PHCollectionList *> *result = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
        if (result && result.count > 0) {
            PHCollectionList *parent = result.firstObject;

            [PHPhotoLibrary.sharedPhotoLibrary
             performChangesAndWait:^{
                PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
                targetId = request.placeholderForCreatedAssetCollection.localIdentifier;
            } error:&error];

            if (error) {
                NSLog(@"createAlbumWithName 1: error : %@", error);
            }

            [PHPhotoLibrary.sharedPhotoLibrary
             performChangesAndWait:^{
                PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest changeRequestForCollectionList:parent];
                PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[targetId] options:nil];
                [request addChildCollections:fetchResult];
            } error:&error];

            if (error) {
                NSLog(@"createAlbumWithName 2: error : %@", error);
            }

            block(targetId, error.localizedDescription);

        } else {
            block(nil, [NSString stringWithFormat:@"Cannot find folder : %@", id]);
            return;
        }
    } else { // create in top
        [PHPhotoLibrary.sharedPhotoLibrary
         performChangesAndWait:^{
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
            targetId = request.placeholderForCreatedAssetCollection.localIdentifier;
        } error:&error];

        if (error) {
            NSLog(@"createAlbumWithName 3: error : %@", error);
        }
        block(targetId, error.localizedDescription);
    }
}

- (void)removeInAlbumWithAssetId:(NSArray *)id albumId:(NSString *)albumId block:(void (^)(NSString *))block {
    PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumId] options:nil];
    PHAssetCollection *collection;
    if (result && result.count > 0) {
        collection = result.firstObject;
    } else {
        block(@"Can't found the collection.");
        return;
    }

    if (![collection canPerformEditOperation:PHCollectionEditOperationRemoveContent]) {
        block(@"The collection cannot remove asset by user.");
        return;
    }

    PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsWithLocalIdentifiers:id options:nil];
    NSError *error;
    [PHPhotoLibrary.sharedPhotoLibrary
     performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        [request removeAssets:assetResult];
    } error:&error];
    if (error) {
        block([NSString stringWithFormat:@"Remove error: %@", error]);
        return;
    }

    block(nil);
}

- (id)getFirstObjFromFetchResult:(PHFetchResult<id> *)fetchResult {
    if (fetchResult && fetchResult.count > 0) {
        return fetchResult.firstObject;
    }
    return nil;
}

- (void)removeCollectionWithId:(NSString *)id type:(int)type block:(void (^)(NSString *))block {
    if (type == 1) {
        PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id] options:nil];
        PHAssetCollection *collection = [self getFirstObjFromFetchResult:fetchResult];
        if (!collection) {
            block(@"Cannot found asset collection.");
            return;
        }
        if (![collection canPerformEditOperation:PHCollectionEditOperationDelete]) {
            block(@"The asset collection can be delete.");
            return;
        }
        NSError *error;
        [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
            [PHAssetCollectionChangeRequest deleteAssetCollections:@[collection]];
        }                                                  error:&error];

        if (error) {
            block([NSString stringWithFormat:@"Remove error: %@", error]);
            return;
        }

        block(nil);

    } else if (type == 2) {
        PHFetchResult<PHCollectionList *> *fetchResult = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
        PHCollectionList *collection = [self getFirstObjFromFetchResult:fetchResult];
        if (!collection) {
            block(@"Cannot found collection list.");
            return;
        }
        if (![collection canPerformEditOperation:PHCollectionEditOperationDelete]) {
            block(@"The collection list can be delete.");
            return;
        }
        NSError *error;
        [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
            [PHCollectionListChangeRequest deleteCollectionLists:@[collection]];
        }                                                  error:&error];

        if (error) {
            block([NSString stringWithFormat:@"Remove error: %@", error]);
            return;
        }

        block(nil);
    } else {
        block(@"Not support the type");
    }
}

- (BOOL)favoriteWithId:(NSString *)id favorite:(BOOL)favorite {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[id] options:nil];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (!asset) {
        NSLog(@"Favoriting asset %@ failed: Asset not found.",id);
        return NO;
    }

    NSError *error;
    BOOL canPerformEditOperation = [asset canPerformEditOperation:PHAssetEditOperationProperties];
    if (!canPerformEditOperation) {
        NSLog(@"Favoriting asset %@ failed: Cannot perform edit operation.", id);
        return NO;
    }
    BOOL succeed = [PHPhotoLibrary.sharedPhotoLibrary
                    performChangesAndWait:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:asset];
        request.favorite = favorite;
    } error:&error];
    if (!succeed) {
        NSLog(@"Favoriting asset %@ failed: Request not succeed.", id);
        return NO;
    }
    if (error) {
        NSLog(@"Favoriting asset %@ failed: %@.", id, error);
        return NO;
    }
    return YES;
}

- (NSString *)getCachePath:(NSString *)type {
    NSString *homePath = NSTemporaryDirectory();
    NSString *cachePath = type;
    NSString *dirPath = [NSString stringWithFormat:@"%@%@", homePath, cachePath];
    return dirPath;
}

- (void)clearFileCache {
    NSString *imagePath = [self getCachePath:PM_IMAGE_CACHE_PATH];
    NSString *videoPath = [self getCachePath:PM_VIDEO_CACHE_PATH];
    NSString *fullFilePath = [self getCachePath:PM_FULL_IMAGE_CACHE_PATH];

    NSError *err;
    [PMFileHelper deleteFile:imagePath isDirectory:YES error:err];
    if (err) {
        [PMLogUtils.sharedInstance
         info:[NSString stringWithFormat:@"Remove .image cache %@, error: %@", imagePath, err]];
    }
    [PMFileHelper deleteFile:videoPath isDirectory:YES error:err];
    if (err) {
        [PMLogUtils.sharedInstance
         info:[NSString stringWithFormat:@"Remove .video cache %@, error: %@", videoPath, err]];
    }

    [PMFileHelper deleteFile:fullFilePath isDirectory:YES error:err];
    if (err) {
        [PMLogUtils.sharedInstance
         info:[NSString stringWithFormat:@"Remove .full file cache %@, error: %@", fullFilePath, err]];
    }

}

#pragma mark cache thumb

- (void)requestCacheAssetsThumb:(NSArray *)identifiers option:(PMThumbLoadOption *)option {
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:identifiers options:nil];
    NSMutableArray *array = [NSMutableArray new];

    for (id asset in fetchResult) {
        [array addObject:asset];
    }

    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.resizeMode = options.resizeMode;
    options.deliveryMode = option.deliveryMode;

    [self.cachingManager startCachingImagesForAssets:array targetSize:[option makeSize] contentMode:option.contentMode options:options];
}

- (void)cancelCacheRequests {
    [self.cachingManager stopCachingImagesForAllAssets];
}

- (void)notifyProgress:(NSObject <PMProgressHandlerProtocol> *)handler progress:(double)progress state:(PMProgressState)state {
    if (!handler) {
        return;
    }

    [handler notify:progress state:state];
}

- (void)notifySuccess:(NSObject <PMProgressHandlerProtocol> *)handler {
    [self notifyProgress:handler progress:1 state:PMProgressStateSuccess];
    [handler deinit];
}


#pragma mark inject modify date

- (void)injectModifyToDate:(PMAssetPathEntity *)path {
    NSString *pathId = path.id;
    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[pathId] options:nil];
    if (fetchResult.count > 0) {
        PHAssetCollection *collection = fetchResult.firstObject;

        PHFetchOptions *options = [PHFetchOptions new];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO];
        options.sortDescriptors = @[sortDescriptor];

        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        PHAsset *asset = assets.firstObject;
        path.modifiedDate = (long) asset.modificationDate.timeIntervalSince1970;
    }
}

@end
