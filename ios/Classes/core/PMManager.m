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

- (PHFetchOptions *)singleFetchOptions {
    PHFetchOptions *options = [PHFetchOptions new];
    options.fetchLimit = 1;
    return options;
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
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:[self singleFetchOptions]];
    return result && result.count == 1;
}

- (BOOL)entityIsLocallyAvailable:(NSString *)assetId
                        resource:(PHAssetResource *)resource
                        isOrigin:(BOOL)isOrigin
                         subtype:(int)subtype
                        fileType:(AVFileType)fileType {
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:[self singleFetchOptions]];
    if (!result) {
        return NO;
    }
    PHAsset *asset = result.firstObject;
    if (@available(iOS 9.1, *)) {
        if ((subtype & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
            resource = [asset getLivePhotosResource];
        }
    }
    if (@available(macOS 14.0, *)) {
        if ((subtype & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
            resource = [asset getLivePhotosResource];
        }
    }
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset
                                      resource:resource
                                      isOrigin:isOrigin
                                      fileType:fileType
                                       manager:fileManager];
    BOOL isExist = [fileManager fileExistsAtPath:path];
    [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Locally available for path %@: %hhd", path, isExist]];
    if (isExist) {
        return YES;
    }
    if (!resource) {
        resource = [asset getCurrentResource];
    }
    if (!resource) {
        return NO;
    }
    // If this returns NO, then the asset is in iCloud or not saved locally yet.
    isExist = [[resource valueForKey:@"locallyAvailable"] boolValue];
    [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Locally available for asset %@ resource %@: %hhd", assetId, resource, isExist]];
    return isExist;
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
    NSArray<NSSortDescriptor *> *sortDescriptors = assetOptions.sortDescriptors;
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
        if (sortDescriptors == nil || sortDescriptors.count == 0) {
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
    NSArray<NSSortDescriptor *> *sortDescriptors = assetOptions.sortDescriptors;
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
        if (sortDescriptors == nil || sortDescriptors.count == 0) {
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
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:[self singleFetchOptions]];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (!asset) {
        return nil;
    }
    entity = [self convertPHAssetToAssetEntity:asset needTitle:NO];
    [cacheContainer putAssetEntity:entity];
    return entity;
}

- (void)clearCache {
    [cacheContainer clearCache];
}

- (void)getThumbWithId:(NSString *)assetId option:(PMThumbLoadOption *)option resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PMAssetEntity *entity = [self getAssetEntity:assetId];
    if (entity && entity.phAsset) {
        PHAsset *asset = entity.phAsset;
        [self fetchThumb:asset option:option resultHandler:handler progressHandler:progressHandler];
    } else {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ is not found", assetId]];
    }
}

- (void)fetchThumb:(PHAsset *)asset option:(PMThumbLoadOption *)option resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
    requestOptions.deliveryMode = option.deliveryMode;
    requestOptions.resizeMode = option.resizeMode;
    [requestOptions setNetworkAccessAllowed:YES];
    
    __block double lastProgress = 0.0;
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [requestOptions setProgressHandler:^(double progress, NSError *error, BOOL *stop,
                                         NSDictionary *info) {
        if (error) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            return;
        }
        lastProgress = progress;
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    int width = option.width;
    int height = option.height;
    
    [self.cachingManager requestImageForAsset:asset
                                   targetSize:CGSizeMake(width, height)
                                  contentMode:option.contentMode
                                      options:requestOptions
                                resultHandler:^(PMImage *result, NSDictionary *info) {
        if ([handler isReplied]) {
            return;
        }
        
        NSObject *error = info[PHImageErrorKey];
        if (error) {
            [handler replyError:error];
            [self notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
            return;
        }
        
        BOOL downloadFinished = [PMManager isDownloadFinish:info];
        if (!downloadFinished) {
            return;
        }
        
        NSData *imageData = [PMImageUtil convertToData:result formatType:option.format quality:option.quality];
        if (imageData) {
            id data = [self.converter convertData:imageData];
            [handler reply:data];
            [self notifySuccess:progressHandler];
        } else {
            [handler replyError:[NSString stringWithFormat:@"Failed to convert %@ to %u format.", asset.localIdentifier, option.format]];
            [self notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
        }
        
    }];
    
}

- (void)getFullSizeFileWithId:(NSString *)assetId
                     isOrigin:(BOOL)isOrigin
                      subtype:(int)subtype
                     fileType:(AVFileType)fileType
                resultHandler:(NSObject <PMResultHandler> *)handler
              progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PMAssetEntity *entity = [self getAssetEntity:assetId];
    if (entity && entity.phAsset) {
        PHAsset *asset = entity.phAsset;
        if (@available(iOS 9.1, *)) {
            if (asset.isLivePhoto && (subtype & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
                [self fetchLivePhotosFile:asset handler:handler progressHandler:progressHandler withScheme:NO fileType:fileType];
                return;
            }
        }
        if (@available(macOS 14.0, *)) {
            if (asset.isLivePhoto && (subtype & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
                [self fetchLivePhotosFile:asset handler:handler progressHandler:progressHandler withScheme:NO fileType:fileType];
                return;
            }
        }
        if (asset.isVideo) {
            if (isOrigin) {
                [self fetchOriginVideoFile:asset handler:handler progressHandler:progressHandler fileType:fileType];
            } else {
                [self fetchFullSizeVideo:asset handler:handler progressHandler:progressHandler withScheme:NO fileType:fileType];
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
    [handler replyError:[NSString stringWithFormat:@"Asset %@ file cannot be obtained.", assetId]];
}

- (void)fetchLivePhotosFile:(PHAsset *)asset
                    handler:(NSObject <PMResultHandler> *)handler
            progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                 withScheme:(BOOL)withScheme
                   fileType:(AVFileType)fileType {
    PHAssetResource *resource = [asset getLivePhotosResource];
    if (!resource) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ does not have a Live-Photo resource.", asset.localIdentifier]];
        return;
    }
    
    [self fetchVideoResourceToFile:asset
                          resource:resource
                   progressHandler:progressHandler
                        withScheme:withScheme
                          isOrigin:YES
                          fileType:fileType
                             block:^(NSString *path, NSObject *error) {
        if (path) {
            [handler reply:path];
        } else {
            [handler replyError:error];
        }
    }];
}

- (void)fetchOriginVideoFile:(PHAsset *)asset
                     handler:(NSObject <PMResultHandler> *)handler
             progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                    fileType:(AVFileType)fileType {
    PHAssetResource *resource = [asset getCurrentResource];
    if (!resource) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ does not have available resources.", asset.localIdentifier]];
        return;
    }
    [self fetchVideoResourceToFile:asset
                          resource:resource
                   progressHandler:progressHandler
                        withScheme:NO
                          isOrigin:YES
                          fileType:fileType
                             block:^(NSString *path, NSObject *error) {
        if (path) {
            [handler reply:path];
        } else {
            [handler replyError:error];
        }
    }];
}

- (void)fetchFullSizeVideo:(PHAsset *)asset
                   handler:(NSObject <PMResultHandler> *)handler
           progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                withScheme:(BOOL)withScheme
                  fileType:(AVFileType)fileType {
    [self exportAssetToFile:asset
            progressHandler:progressHandler
                 withScheme:withScheme
                   fileType:fileType
                      block:^(NSString *path, NSObject *error) {
        if (path) {
            [handler reply:path];
        } else {
            [handler replyError:error];
        }
    }];
}

- (void)fetchVideoResourceToFile:(PHAsset *)asset
                        resource:(PHAssetResource *)resource
                 progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                      withScheme:(BOOL)withScheme
                        isOrigin:(BOOL)isOrigin
                        fileType:(AVFileType)fileType
                           block:(void (^)(NSString *path, NSObject *error))block {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset
                                      resource:resource
                                      isOrigin:isOrigin
                                      fileType:nil
                                       manager:fileManager];
    if ([fileManager fileExistsAtPath:path]) {
        if (fileType) {
            NSString *newPath = [self makeAssetOutputPath:asset
                                              resource:resource
                                              isOrigin:isOrigin
                                              fileType:fileType
                                               manager:fileManager];
            if ([fileManager fileExistsAtPath:newPath]) {
                [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", newPath]];
                [self notifySuccess:progressHandler];
                if (withScheme) {
                    block([NSURL fileURLWithPath:newPath].absoluteString, nil);
                } else {
                    block(newPath, nil);
                }
                return;
            }
            [self exportAVAssetToFile:[AVAsset assetWithURL:[NSURL fileURLWithPath:path]]
                          destination:newPath
                      progressHandler:progressHandler
                           withScheme:withScheme
                             fileType:fileType
                                block:^(NSString *path, NSObject *error) {
                if (path) {
                    if (withScheme) {
                        block([NSURL fileURLWithPath:path].absoluteString, nil);
                    } else {
                        block(path, nil);
                    }
                } else {
                    block(nil, error);
                }
            }];
            return;
        }
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        [self notifySuccess:progressHandler];
        if (withScheme) {
            block([NSURL fileURLWithPath:path].absoluteString, nil);
        } else {
            block(path, nil);
        }
        return;
    }
    
    PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
    [options setNetworkAccessAllowed:YES];
    
    __block double lastProgress = 0.0;
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress) {
        lastProgress = progress;
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    
    PHAssetResourceManager *resourceManager = PHAssetResourceManager.defaultManager;
    __block NSURL *fileUrl = [NSURL fileURLWithPath:path];
    [resourceManager writeDataForAssetResource:resource
                                        toFile:fileUrl
                                       options:options
                             completionHandler:^(NSError *_Nullable error) {
        if (error) {
            [self notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
            block(nil, error);
            return;
        }
        if (fileType) {
            NSString *newPath = [self makeAssetOutputPath:asset
                                              resource:resource
                                              isOrigin:isOrigin
                                              fileType:fileType
                                               manager:fileManager];
            [self exportAVAssetToFile:[AVAsset assetWithURL:[NSURL fileURLWithPath:path]]
                          destination:newPath
                      progressHandler:progressHandler
                           withScheme:withScheme
                             fileType:fileType
                                block:^(NSString *path, NSObject *error) {
                if (path) {
                    if (withScheme) {
                        block([NSURL fileURLWithPath:path].absoluteString, nil);
                    } else {
                        block(path, nil);
                    }
                } else {
                    block(nil, error);
                }
            }];
            return;
        }
        [self notifySuccess:progressHandler];
        if (withScheme) {
            block([NSURL fileURLWithPath:path].absoluteString, nil);
        } else {
            block(path, nil);
        }
    }];
}

- (void)exportAssetToFile:(PHAsset *)asset
          progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
               withScheme:(BOOL)withScheme
                 fileType:(AVFileType)fileType
                    block:(void (^)(NSString *path, NSObject *error))block {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset resource:nil isOrigin:NO fileType:fileType manager:manager];
    if ([manager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Read cache from %@", path]];
        if (withScheme) {
            block([NSURL fileURLWithPath:path].absoluteString, nil);
        } else {
            block(path, nil);
        }
    }

    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    [options setDeliveryMode:PHVideoRequestOptionsDeliveryModeAutomatic];
    [options setNetworkAccessAllowed:YES];
    [options setVersion:PHVideoRequestOptionsVersionCurrent];

    __block double lastProgress = 0.0;
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        lastProgress = progress;
        if (error) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            return;
        }
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    
    [self.cachingManager
     requestAVAssetForVideo:asset
     options:options
     resultHandler:^(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info) {
        NSObject *error = info[PHImageErrorKey];
        if (error) {
            [self notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
            block(nil, error);
            return;
        }
        
        BOOL downloadFinished = [PMManager isDownloadFinish:info];
        if (!downloadFinished) {
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
                    block(videoURL.absoluteString, nil);
                } else {
                    block([videoURL path], nil);
                }
                [self notifySuccess:progressHandler];
                return;
            }
            NSError *error;
            NSString *destinationPath = destination.path;
            if ([manager fileExistsAtPath:destinationPath]) {
                [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Reading cache from %@", destinationPath]];
                if (withScheme) {
                    block(destination.absoluteString, nil);
                } else {
                    block(destinationPath, nil);
                }
                [self notifySuccess:progressHandler];
                return;
            }
            [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Caching the video to %@", destination]];
            [[NSFileManager defaultManager] copyItemAtURL:videoURL
                                                    toURL:destination
                                                    error:&error];
            if (error) {
                block(nil, error);
                [self notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
                return;
            }
            if (withScheme) {
                block(destination.absoluteString, nil);
            } else {
                block(path, nil);
            }
            [self notifySuccess:progressHandler];
            return;
        }
        
        [self exportAVAssetToFile:asset
                      destination:path
                  progressHandler:progressHandler
                       withScheme:withScheme
                         fileType:fileType
                            block:^(NSString *path, NSObject *error) {
            if (path) {
                if (withScheme) {
                    block([NSURL fileURLWithPath:path].absoluteString, nil);
                } else {
                    block(path, nil);
                }
            } else {
                block(nil, error);
            }
        }];
    }];
}

- (void)exportAVAssetToFile:(AVAsset *)asset
                destination:(NSString *)destination
            progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                 withScheme:(BOOL)withScheme
                   fileType:(AVFileType)fileType
                      block:(void (^)(NSString *path, NSObject *error))block {
    // Export the asset eventually, typically for `AVComposition`s.
    AVAssetExportSession *exportSession = [AVAssetExportSession
                                           exportSessionWithAsset:asset
                                           presetName:AVAssetExportPresetHighestQuality];
    if (exportSession) {
        NSString *extension = [[destination pathExtension] lowercaseString];
        // Determine the output type for the fastest speed.
        AVFileType outputFileType;
        if (fileType != nil) {
            outputFileType = fileType;
        } else if ([extension isEqualToString:@"mov"]) {
            outputFileType = AVFileTypeQuickTimeMovie;
        } else if ([extension isEqualToString:@"m4v"]) {
            outputFileType = AVFileTypeAppleM4V;
        } else {
            outputFileType = AVFileTypeMPEG4;
        }
        exportSession.outputFileType = outputFileType;
        exportSession.outputURL = [NSURL fileURLWithPath:destination];
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSString *result;
                if (withScheme) {
                    result = [NSURL fileURLWithPath:destination].absoluteString;
                } else {
                    result = destination;
                }
                NSString *resultExtension = [[result pathExtension] lowercaseString];
                NSString *targetExtension;
                if (outputFileType == AVFileTypeQuickTimeMovie) {
                    targetExtension = @"mov";
                } else if (outputFileType == AVFileTypeAppleM4V) {
                    targetExtension = @"m4v";
                } else {
                    targetExtension = @"mp4";
                }
                if (![resultExtension isEqualToString:targetExtension]) {
                    [self notifyProgress:progressHandler progress:0.0 state:PMProgressStateFailed];
                    block(nil, [NSString stringWithFormat:@"Incorrect exported file extension, expecting %@, got %@", targetExtension, resultExtension]);
                } else {
                    [self notifySuccess:progressHandler];
                    block(result, nil);
                }
            } else if (exportSession.status == AVAssetExportSessionStatusFailed ||
                       exportSession.status == AVAssetExportSessionStatusCancelled) {
                [self notifyProgress:progressHandler progress:0.0 state:PMProgressStateFailed];
                block(nil, exportSession.error);
            }
        }];
        return;
    }
    [self notifyProgress: progressHandler progress:0.0 state:PMProgressStateFailed];
    block(nil, @"Unable to initialize an export session.");
}

- (NSString *)makeAssetOutputPath:(PHAsset *)asset
                         resource:(PHAssetResource *)resource
                         isOrigin:(Boolean)isOrigin
                         fileType:(AVFileType)fileType
                          manager:(NSFileManager *)manager {
    NSString *id = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *modifiedDate = [NSString stringWithFormat:@"%f", asset.modificationDate.timeIntervalSince1970];
    NSString *homePath = NSTemporaryDirectory();
    NSMutableString *path = [NSMutableString stringWithString:homePath];
    NSString *filename;
    if (resource) {
        filename = resource.originalFilename;
    } else {
        filename = [asset title];
    }
    filename = [NSString stringWithFormat:@"%@_%@%@_%@",
                id, modifiedDate, isOrigin ? @"_o" : @"", filename];
    if (fileType) {
        NSString *newExtension = [PMConvertUtils convertAVFileTypeToExtension:fileType];
        if (newExtension) {
            NSString *filenameWithoutExtension = [filename stringByDeletingPathExtension];
            filename = [filenameWithoutExtension stringByAppendingPathExtension:[newExtension stringByReplacingOccurrencesOfString:@"." withString:@""]];
        }
    }
    
    // Convert the extension to lowercased.
    NSString *extension = [filename pathExtension];
    filename = [filename stringByDeletingPathExtension];
    filename = [filename stringByAppendingPathExtension:[extension stringByReplacingOccurrencesOfString:@"." withString:@""]];
    
    NSString *typeDirPath;
    if (resource) {
        if (resource.isImage) {
            typeDirPath = PM_IMAGE_CACHE_PATH;
        } else if (resource.isVideo) {
            typeDirPath = PM_VIDEO_CACHE_PATH;
        } else if (resource.isAudio) {
            typeDirPath = PM_AUDIO_CACHE_PATH;
        } else {
            typeDirPath = PM_OTHER_CACHE_PATH;
        }
    } else {
        if (asset.isImage) {
            typeDirPath = PM_IMAGE_CACHE_PATH;
        } else if (asset.isVideo) {
            typeDirPath = PM_VIDEO_CACHE_PATH;
        } else if (asset.isAudio) {
            typeDirPath = PM_AUDIO_CACHE_PATH;
        } else {
            typeDirPath = PM_OTHER_CACHE_PATH;
        }
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
    PHAssetResource *imageResource = [asset getCurrentResource];
    if (!imageResource) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ does not have available resources.", asset.localIdentifier]];
        return;
    }
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset
                                      resource:imageResource
                                      isOrigin:YES
                                      fileType:nil
                                       manager:fileManager];
    if ([fileManager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        [handler reply:path];
        return;
    }
    
    PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
    [options setNetworkAccessAllowed:YES];
    
    __block double lastProgress = 0.0;
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress) {
        lastProgress = progress;
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
            [self notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
            [handler replyError:error];
        } else {
            [handler reply:path];
            [self notifySuccess:progressHandler];
        }
    }];
}

- (void)fetchFullSizeImageFile:(PHAsset *)asset
                 resultHandler:(NSObject <PMResultHandler> *)handler
               progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeOpportunistic];
    [options setNetworkAccessAllowed:YES];
    [options setResizeMode:PHImageRequestOptionsResizeModeNone];
    [options setSynchronous:YES];
    [options setVersion:PHImageRequestOptionsVersionCurrent];
    
    __block double lastProgress = 0.0;
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop,
                                  NSDictionary *info) {
        if (error) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            return;
        }
        lastProgress = progress;
        if (progress != 1) {
            [self notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    
    [self.cachingManager requestImageForAsset:asset
                                   targetSize:PHImageManagerMaximumSize
                                  contentMode:PHImageContentModeDefault
                                      options:options
                                resultHandler:^(PMImage *_Nullable image, NSDictionary *_Nullable info) {
        if ([handler isReplied]) {
            return;
        }
        
        NSObject *error = info[PHImageErrorKey];
        if (error) {
            [handler replyError:error];
            [self notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
            return;
        }
        
        BOOL downloadFinished = [PMManager isDownloadFinish:info];
        if (!downloadFinished) {
            return;
        }
        
        NSData *data = [PMImageUtil convertToData:image formatType:PMThumbFormatTypeJPEG quality:1.0];
        if (data) {
            NSString *path = [self writeFullFileWithAssetId:asset imageData: data];
            [handler reply:path];
            [self notifySuccess:progressHandler];
        } else {
            [handler replyError:[NSString stringWithFormat:@"Failed to convert %@ to a JPEG file.", asset.localIdentifier]];
            [self notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
        }
    }];
}

+ (BOOL)isDownloadFinish:(NSDictionary *)info {
    BOOL finished;
    finished = ![info[PHImageCancelledKey] boolValue]; // Not cancelled.
    finished = ![info[PHImageResultIsDegradedKey] boolValue]; // Not thumbnail.
    return finished;
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
            [result reply:@(success)];
        }];
    } else if (@available(iOS 8.0, *)) {
        BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        [result reply:@(success)];
    } else {
        [result reply:@false];
    }
}

#endif

#pragma clang diagnostic pop

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block {
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHFetchOptions *options = [PHFetchOptions new];
        options.fetchLimit = ids.count;
        PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:ids options:options];
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
         filename:(NSString *)filename
             desc:(NSString *)desc
            block:(AssetBlockResult)block {
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Saving image with data, length: %lu, filename: %@, desc: %@", (unsigned long)data.length, filename, desc]];

    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        [options setOriginalFilename:filename];
        [request addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Created image %@", assetId]];
            block([self getAssetEntity:assetId], nil);
        } else {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Save image with data failed %@, reason = %@", assetId, error]];
            block(nil, error);
        }
    }];
}

- (void)saveImageWithPath:(NSString *)path
                 filename:(NSString *)filename
                     desc:(NSString *)desc
                    block:(AssetBlockResult)block {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        block(nil, [NSString stringWithFormat:@"File does not exist at %@", path]);
        return;
    }

    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Saving image with path: %@ filename: %@, desc: %@", path, filename, desc]];
    
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        if (filename) {
            [options setOriginalFilename:filename];
        }
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:fileURL options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
            block([self getAssetEntity:assetId], nil);
        } else {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Save image with path failed %@, reason = %@", assetId, error]];
            block(nil, error);
        }
    }];
}

- (void)saveVideo:(NSString *)path
         filename:(NSString *)filename
             desc:(NSString *)desc
            block:(AssetBlockResult)block {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        block(nil, [NSString stringWithFormat:@"File does not exist at %@", path]);
        return;
    }

    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Saving video with path: %@, filename: %@, desc %@", path, filename, desc]];

    NSURL *fileURL = [NSURL fileURLWithPath:path];
    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        if (filename) {
            [options setOriginalFilename:filename];
        }
        [request addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:options];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
            block([self getAssetEntity:assetId], nil);
        } else {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Save video with path failed %@, reason = %@", assetId, error]];
            block(nil, error);
        }
    }];
}

- (void)saveLivePhoto:(NSString *)imagePath
            videoPath:(NSString *)videoPath
                title:(NSString *)title
                 desc:(NSString *)desc
                block:(AssetBlockResult)block {
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Saving Live Photo with imagePath: %@, videoPath: %@, filename: %@, desc: %@", imagePath, videoPath, title, desc]];
    NSURL *imageURL = [NSURL fileURLWithPath:imagePath];
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];

    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *imageOptions = [PHAssetResourceCreationOptions new];
        [imageOptions setOriginalFilename:title];
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:imageOptions];
        PHAssetResourceCreationOptions *videoOptions = [PHAssetResourceCreationOptions new];
        [videoOptions setOriginalFilename:title];
        [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:videoURL options:videoOptions];
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Created Live Photo asset = %@", assetId]];
            block([self getAssetEntity:assetId], nil);
        } else {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Create Live Photo asset failed = %@, %@", assetId, error]];
            block(nil, error);
        }
    }];
}

- (void)getDurationWithOptions:(NSString *)assetId
                       subtype:(int)subtype
                 resultHandler:(NSObject<PMResultHandler> *)handler {
    PMAssetEntity *entity = [self getAssetEntity:assetId];
    if (!entity) {
        [handler replyError:@"Not exists."];
        return;
    }
    PHAsset *asset = entity.phAsset;
    if (!asset) {
        [handler replyError:@"Not exists."];
        return;
    }
    
    if (asset.isLivePhoto) {
        PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
        options.networkAccessAllowed = YES;
        [asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
            if (!contentEditingInput) {
                [handler replyError:@"Failed to obtain the content request."];
                return;
            }
            PHLivePhotoEditingContext *context = [[PHLivePhotoEditingContext alloc] initWithLivePhotoEditingInput:contentEditingInput];
            if (!context) {
                [handler replyError:@"Failed to obtain the Live Photo's context."];
                return;
            }
            NSTimeInterval time = CMTimeGetSeconds(context.duration);
            [handler reply:@((long) time)];
        }];
        return;
    }
    
    [handler reply:@(entity.duration)];
    return;
}


- (NSString *)getTitleAsyncWithAssetId:(NSString *)assetId
                               subtype:(int)subtype
                              isOrigin:(BOOL)isOrigin
                              fileType:(AVFileType)fileType {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:[self singleFetchOptions]];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (asset) {
        return [asset filenameWithOptions:subtype isOrigin:isOrigin fileType:fileType];
    }
    return @"";
}

- (NSString *)getMimeTypeAsyncWithAssetId:(NSString *)assetId {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:[self singleFetchOptions]];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (asset) {
        return [asset mimeType];
    }
    return nil;
}

- (void)getMediaUrl:(NSString *)assetId
      resultHandler:(NSObject <PMResultHandler> *)handler
    progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:[self singleFetchOptions]].firstObject;
    
    if (@available(iOS 9.1, *)) {
        if ((asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
            // https://github.com/fluttercandies/flutter_photo_manager/issues/1196
            if (@available(iOS 18.0, *)) {
                [self fetchLivePhotosFile:asset handler:handler progressHandler:progressHandler withScheme:YES fileType:nil];
                return;
            }
            PHAssetResource *resource = [asset getLivePhotosResource];
            NSURL *url = [resource valueForKey:@"privateFileURL"];
            if (url) {
                [handler reply:url.absoluteString];
                return;
            }
            [self fetchLivePhotosFile:asset handler:handler progressHandler:progressHandler withScheme:YES fileType:nil];
            return;
        }
    }
    if (@available(macOS 14.0, *)) {
        if ((asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
            PHAssetResource *resource = [asset getLivePhotosResource];
            NSURL *url = [resource valueForKey:@"privateFileURL"];
            if (url) {
                [handler reply:url.absoluteString];
                return;
            }
            [self fetchLivePhotosFile:asset handler:handler progressHandler:progressHandler withScheme:YES fileType:nil];
            return;
        }
    }
    
    if (asset.isVideo) {
        [self fetchFullSizeVideo:asset handler:handler progressHandler:progressHandler withScheme:YES fileType:nil];
    } else {
        [handler replyError:@"Only video type of assets can get a media url."];
        [self notifyProgress:progressHandler progress:0 state:PMProgressStateFailed];
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

- (void)copyAssetWithId:(NSString *)id
              toGallery:(NSString *)gallery
                  block:(void (^)(PMAssetEntity *entity, NSObject *error))block {
    PMAssetEntity *assetEntity = [self getAssetEntity:id];
    
    if (!assetEntity) {
        NSString *msg = [NSString stringWithFormat:@"Asset [%@] not found.", id];
        block(nil, msg);
        return;
    }
    
    PHAssetCollection *collection = [self getCollectionWithId:gallery];
    
    if (!collection) {
        block(nil, [NSString stringWithFormat:@"Collection [%@] not found.", gallery]);
        return;
    }
    
    NSString *collectionId = collection.localIdentifier;
    if (![collection canPerformEditOperation:PHCollectionEditOperationAddContent]) {
        block(nil, [NSString stringWithFormat:@"The collection %@ cannot perform content adding operation.", collectionId]);
        return;
    }
    
    __block PHFetchResult<PHAsset *> *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[id] options:[self singleFetchOptions]];
    NSError *error;
    [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        [request addAssets:asset];
    } error:&error];
    if (error) {
        block(nil, error);
    } else {
        block(assetEntity, nil);
    }
}

- (void)createFolderWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *newId, NSObject *error))block {
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

- (void)createAlbumWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *newId, NSObject *error))block {
    __block NSString *targetId;
    NSObject *error;
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
                block(nil, error);
                return;
            }
            
            [PHPhotoLibrary.sharedPhotoLibrary
             performChangesAndWait:^{
                PHCollectionListChangeRequest *request = [PHCollectionListChangeRequest changeRequestForCollectionList:parent];
                PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[targetId] options:nil];
                [request addChildCollections:fetchResult];
            } error:&error];
            if (error) {
                block(nil, error);
                return;
            }
            
            block(targetId, nil);
        } else {
            block(nil, [NSString stringWithFormat:@"Folder [%@] is not found.", id]);
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
        
        block(targetId, nil);
    }
}

- (void)removeInAlbumWithAssetId:(NSArray *)ids albumId:(NSString *)albumId block:(void (^)(NSObject *error))block {
    PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumId] options:nil];
    PHAssetCollection *collection;
    if (result && result.count > 0) {
        collection = result.firstObject;
    } else {
        block([NSString stringWithFormat:@"Collection [%@] not found.", albumId]);
        return;
    }
    
    if (![collection canPerformEditOperation:PHCollectionEditOperationRemoveContent]) {
        block(@"The collection cannot perform content remove operation.");
        return;
    }
    
    PHFetchOptions *options = [PHFetchOptions new];
    options.fetchLimit = ids.count;
    PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsWithLocalIdentifiers:ids options:options];
    NSError *error;
    [PHPhotoLibrary.sharedPhotoLibrary
     performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        [request removeAssets:assetResult];
    } error:&error];
    if (error) {
        block(error);
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

- (void)removeCollectionWithId:(NSString *)id type:(int)type block:(void (^)(NSObject *error))block {
    if (type == 1) {
        PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id] options:nil];
        PHAssetCollection *collection = [self getFirstObjFromFetchResult:fetchResult];
        if (!collection) {
            block([NSString stringWithFormat:@"Collection [%@] not found.", id]);
            return;
        }
        if (![collection canPerformEditOperation:PHCollectionEditOperationDelete]) {
            block(@"The collection cannot perform delete operation.");
            return;
        }
        NSError *error;
        [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
            [PHAssetCollectionChangeRequest deleteAssetCollections:@[collection]];
        }                                                  error:&error];
        
        if (error) {
            block(error);
            return;
        }
        block(nil);
    } else if (type == 2) {
        PHFetchResult<PHCollectionList *> *fetchResult = [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
        PHCollectionList *collection = [self getFirstObjFromFetchResult:fetchResult];
        if (!collection) {
            block([NSString stringWithFormat:@"Collection [%@] not found.", id]);
            return;
        }
        if (![collection canPerformEditOperation:PHCollectionEditOperationDelete]) {
            block(@"The collection cannot perform delete operation.");
            return;
        }
        NSError *error;
        [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
            [PHCollectionListChangeRequest deleteCollectionLists:@[collection]];
        }                                                  error:&error];
        
        if (error) {
            block(error);
            return;
        }
        block(nil);
    } else {
        block([NSString stringWithFormat:@"Unsupported collection type: %d", type]);
    }
}

- (void)favoriteWithId:(NSString *)id favorite:(BOOL)favorite block:(void (^)(BOOL result, NSObject *error))block {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[id] options:[self singleFetchOptions]];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (!asset) {
        block(NO, [NSString stringWithFormat:@"Asset %@ not found.", id]);
        return;
    }
    
    if (![asset canPerformEditOperation:PHAssetEditOperationProperties]) {
        block(NO, [NSString stringWithFormat:@"The asset %@ cannot perform edit operation.", id]);
        return;
    }
    
    NSError *error;
    BOOL succeed = [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:asset];
        request.favorite = favorite;
    } error:&error];
    if (!succeed) {
        block(NO, [NSString stringWithFormat:@"Favouring asset %@ failed: Request not succeed.", id]);
        return;
    }
    if (error) {
        block(NO, error);
        return;
    }
    block(YES, nil);
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

- (void)requestCacheAssetsThumb:(NSArray *)ids option:(PMThumbLoadOption *)option {
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.fetchLimit = ids.count;
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:ids options:fetchOptions];
    NSMutableArray *array = [NSMutableArray new];
    
    for (id asset in fetchResult) {
        [array addObject:asset];
    }
    
    PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
    requestOptions.resizeMode = option.resizeMode;
    requestOptions.deliveryMode = option.deliveryMode;
    
    [self.cachingManager startCachingImagesForAssets:array
                                          targetSize:[option makeSize]
                                         contentMode:option.contentMode
                                             options:requestOptions];
}

- (void)cancelCacheRequests {
    [self.cachingManager stopCachingImagesForAllAssets];
}

- (void)notifyProgress:(NSObject <PMProgressHandlerProtocol> *)handler progress:(double)progress state:(PMProgressState)state {
    if (!handler) {
        return;
    }
    
    NSString *log = [NSString stringWithFormat:@"PMProgress notify progress %f, %u", progress, state];
    [[PMLogUtils sharedInstance] info:log];
    [handler notify:progress state:state];
}

- (void)notifySuccess:(NSObject <PMProgressHandlerProtocol> *)handler {
    [self notifyProgress:handler progress:1 state:PMProgressStateSuccess];
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
