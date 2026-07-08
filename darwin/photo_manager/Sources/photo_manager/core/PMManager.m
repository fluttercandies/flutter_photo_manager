#import "NSObject+SafeCheck.h"
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
#import "PMRequestTypeUtils.h"
#import "PMResultHandler.h"

#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>

static NSString *PMResourceTypeName(PHAssetResourceType type) {
    // Adjustment-base types have newer availability than the plugin's iOS 9
    // deployment target, so guard the comparisons behind `@available` before
    // touching the enum values.
    if (@available(iOS 13.0, macOS 10.15, *)) {
        if (type == PHAssetResourceTypeAdjustmentBaseVideo) return @"adjustmentBaseVideo";
    }
    if (@available(iOS 10.0, macOS 10.15, *)) {
        if (type == PHAssetResourceTypeFullSizePairedVideo) return @"fullSizePairedVideo";
        if (type == PHAssetResourceTypeAdjustmentBasePairedVideo) return @"adjustmentBasePairedVideo";
    }
    if (@available(iOS 9.1, macOS 10.15, *)) {
        if (type == PHAssetResourceTypePairedVideo) return @"pairedVideo";
    }
    switch (type) {
        case PHAssetResourceTypePhoto:                return @"photo";
        case PHAssetResourceTypeVideo:                return @"video";
        case PHAssetResourceTypeAudio:                return @"audio";
        case PHAssetResourceTypeAlternatePhoto:       return @"alternatePhoto";
        case PHAssetResourceTypeFullSizePhoto:        return @"fullSizePhoto";
        case PHAssetResourceTypeFullSizeVideo:        return @"fullSizeVideo";
        case PHAssetResourceTypeAdjustmentData:       return @"adjustmentData";
        case PHAssetResourceTypeAdjustmentBasePhoto:  return @"adjustmentBasePhoto";
        default:
            return [NSString stringWithFormat:@"unknown(%ld)", (long)type];
    }
}

@implementation PMManager {
    PMCacheContainer *cacheContainer;
    
    PHCachingImageManager *__cachingManager;

    // dict, key: cancelToken, value: PHImageRequestID
    NSMutableDictionary<NSString *, NSNumber*> *requestIdMap;
    // Serial queue that serializes all requestIdMap mutations/reads.
    dispatch_queue_t _requestIdQueue;
    dispatch_queue_t _imageFileProcessingQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        cacheContainer = [PMCacheContainer new];
        requestIdMap = [NSMutableDictionary new];
        _requestIdQueue = dispatch_queue_create(
            "com.fluttercandies.photo_manager.requestIdQueue",
            DISPATCH_QUEUE_SERIAL
        );
        _imageFileProcessingQueue = dispatch_queue_create(
            "com.fluttercandies.photo_manager.imageFileProcessingQueue",
            DISPATCH_QUEUE_SERIAL
        );
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

- (PHFetchResult<PHAsset *> *)fetchAssetsWithLocalIdentifiersSafely:(NSArray<NSString *> *)ids
                                                            options:(PHFetchOptions *)options
                                                          operation:(NSString *)operation {
    @try {
        return [PHAsset fetchAssetsWithLocalIdentifiers:ids options:options];
    } @catch (NSException *exception) {
        NSString *log = [NSString stringWithFormat:
                         @"Failed to fetch assets for %@, ids count = %lu, exception = %@, reason = %@",
                         operation,
                         (unsigned long)ids.count,
                         exception.name ?: @"UnknownException",
                         exception.reason ?: @"Unknown reason"];
        [PMLogUtils.sharedInstance info:log];
        return nil;
    }
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
            PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            NSLog(@"collection name = %@, count = %lu", collection.localizedTitle, (unsigned long)result.count);
        } else {
            NSLog(@"collection name = %@", phCollection.localizedTitle);
        }
    }
}

- (NSUInteger)getAssetCountWithType:(int)type option:(NSObject<PMBaseFilter> *)filter {
    PHFetchOptions *options = [self getAssetOptions:type filterOption:filter];
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithOptions:options];
    return result.count;
}

- (NSArray<PMAssetEntity *> *)getAssetsWithType:(int)type option:(NSObject<PMBaseFilter> *)option start:(int)start end:(int)end {
    PHFetchOptions *options = [self getAssetOptions:type filterOption:option];
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
        BOOL needTitle = option ? [option needTitle] : NO;
        PMAssetEntity *pmAsset = [self convertPHAssetToAssetEntity:asset needTitle:needTitle];
        [array addObject: pmAsset];
    }
    
    return array;
}

- (BOOL)existsWithId:(NSString *)assetId {
    PHFetchResult<PHAsset *> *result = [self fetchAssetsWithLocalIdentifiersSafely:@[assetId]
                                                                           options:[self singleFetchOptions]
                                                                         operation:@"existsWithId"];
    return result && result.count == 1;
}

- (BOOL)entityIsLocallyAvailable:(NSString *)assetId
                        resource:(PHAssetResource *)resource
                        isOrigin:(BOOL)isOrigin
                         subtype:(int)subtype
                        fileType:(AVFileType)fileType {
    PHFetchResult<PHAsset *> *result = [self fetchAssetsWithLocalIdentifiersSafely:@[assetId]
                                                                           options:[self singleFetchOptions]
                                                                         operation:@"entityIsLocallyAvailable"];
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
                                                duration:[PMConvertUtils roundDurationSeconds:asset.duration]
                                                    type:type];
    entity.phAsset = asset;
    entity.modifiedDt = modifiedTimeStamp;
    if (asset.location != nil) {
        entity.lat = @(asset.location.coordinate.latitude);
        entity.lng = @(asset.location.coordinate.longitude);
    } else {
        entity.lat = nil;
        entity.lng = nil;
    }
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
    PHFetchResult *fetchResult = [self fetchAssetsWithLocalIdentifiersSafely:@[assetId]
                                                                     options:[self singleFetchOptions]
                                                                   operation:@"getAssetEntity"];
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

- (void)getThumbWithId:(NSString *)assetId option:(PMThumbLoadOption *)option resultHandler:(PMResultHandler *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PMAssetEntity *entity = [self getAssetEntity:assetId];
    if (entity && entity.phAsset) {
        PHAsset *asset = entity.phAsset;
        [self fetchThumb:asset option:option resultHandler:handler progressHandler:progressHandler];
    } else {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ is not found", assetId]];
    }
}

- (void)fetchThumb:(PHAsset *)asset option:(PMThumbLoadOption *)option resultHandler:(PMResultHandler *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
    requestOptions.deliveryMode = option.deliveryMode;
    requestOptions.resizeMode = option.resizeMode;
    [requestOptions setNetworkAccessAllowed:YES];
    
    __block double lastProgress = 0.0;
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    __weak typeof(self) weakSelf = self;
    [requestOptions setProgressHandler:^(double progress, NSError *error, BOOL *stop,
                                         NSDictionary *info) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            return;
        }
        lastProgress = progress;
        if (progress != 1) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    int width = option.width;
    int height = option.height;
    
    // PHImageManager methods must be called on the main thread to avoid crashes
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        PHImageRequestID requestId = [strongSelf.cachingManager requestImageForAsset:asset
                                       targetSize:CGSizeMake(width, height)
                                      contentMode:option.contentMode
                                          options:requestOptions
                                    resultHandler:^(PMImage *result, NSDictionary *info) {
            __strong typeof(weakSelf) innerStrongSelf = weakSelf;
            if (!innerStrongSelf) {
                return;
            }
            
            if ([handler isReplied]) {
                return;
            }
            
            PHImageRequestID currentReqID = [[info objectForKey:PHImageResultRequestIDKey] intValue];
            if (currentReqID == PHInvalidImageRequestID) {
                [innerStrongSelf handleCancelRequest:handler progressHandler:progressHandler];
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
                return;
            }
            
            NSObject *error = info[PHImageErrorKey];
            if (error) {
                [handler replyError:error];
                [innerStrongSelf notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
                return;
            }
            
            BOOL downloadFinished = [PMManager isDownloadFinish:info];
            if (!downloadFinished) {
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
                return;
            }
            
            NSData *imageData = [PMImageUtil convertToData:result formatType:option.format quality:option.quality];
            if (imageData) {
                id data = [innerStrongSelf.converter convertData:imageData];
                [handler reply:data];
                [innerStrongSelf notifySuccess:progressHandler];
            } else {
                [handler replyError:[NSString stringWithFormat:@"Failed to convert %@ to %u format.", asset.localIdentifier, option.format]];
                [innerStrongSelf notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
            }
            
        }];
        
        [strongSelf addRequstId:[handler getCancelToken] requestId:requestId];
    });
}

- (void)getFullSizeFileWithId:(NSString *)assetId
                     isOrigin:(BOOL)isOrigin
                      subtype:(int)subtype
                     fileType:(AVFileType)fileType
                resultHandler:(PMResultHandler *)handler
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
                    handler:(PMResultHandler *)handler
            progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                 withScheme:(BOOL)withScheme
                   fileType:(AVFileType)fileType {
    NSArray<PHAssetResource *> *candidates = [asset candidateResourcesForFetch:YES livePhoto:YES];
    if (candidates.count == 0) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ does not have a Live-Photo resource.", asset.localIdentifier]];
        return;
    }
    NSString *cached = [self cachedPathForAsset:asset
                                     candidates:candidates
                                       isOrigin:YES
                                       fileType:fileType
                            includeFallbackPath:NO];
    if (cached) {
        [self notifySuccess:progressHandler];
        [handler reply:withScheme ? [NSURL fileURLWithPath:cached].absoluteString : cached];
        return;
    }
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [self fetchVideoFileWithCandidates:candidates
                                 asset:asset
                       progressHandler:progressHandler
                            withScheme:withScheme
                              isOrigin:YES
                              fileType:fileType
                                 block:^(NSString *path, NSObject *error) {
        if (path) {
            [handler reply:path];
        } else {
            [self notifyProgress:progressHandler progress:0 state:PMProgressStateFailed];
            [handler replyError:error];
        }
    }];
}

- (void)fetchOriginVideoFile:(PHAsset *)asset
                     handler:(PMResultHandler *)handler
             progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                    fileType:(AVFileType)fileType {
    NSArray<PHAssetResource *> *candidates = [asset candidateResourcesForFetch:YES livePhoto:NO];
    if (candidates.count == 0) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ does not have available resources.", asset.localIdentifier]];
        return;
    }
    NSString *cached = [self cachedPathForAsset:asset
                                     candidates:candidates
                                       isOrigin:YES
                                       fileType:fileType
                            includeFallbackPath:YES];
    if (cached) {
        [self notifySuccess:progressHandler];
        [handler reply:cached];
        return;
    }
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    __weak typeof(self) weakSelf = self;
    [self fetchVideoFileWithCandidates:candidates
                                 asset:asset
                       progressHandler:progressHandler
                            withScheme:NO
                              isOrigin:YES
                              fileType:fileType
                                 block:^(NSString *path, NSObject *walkerError) {
        if (path) {
            [handler reply:path];
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        // Every candidate resource failed (typical iCloud flake). Fall back to
        // PHImageManager's requestAVAssetForVideo pipeline which frequently
        // succeeds when the raw-resource pipeline can't materialize the file.
        [strongSelf fallbackFetchVideoViaAVAsset:asset
                                        isOrigin:YES
                                      withScheme:NO
                                        fileType:fileType
                                 progressHandler:progressHandler
                                           block:^(NSString *fbPath, NSObject *fbError) {
            if (fbPath) {
                [handler reply:fbPath];
                return;
            }
            [strongSelf notifyProgress:progressHandler progress:0 state:PMProgressStateFailed];
            // Prefer the walker's error over the fallback's since it
            // carries the list of resource types we tried.
            [handler replyError:walkerError ?: fbError];
        }];
    }];
}

// Returns the first candidate resource whose cache file already exists, or
// (when `includeFallbackPath` is YES) the AVAsset/image-data fallback cache
// path if present. Used before walking candidates so that assets that
// previously succeeded on a non-first candidate don't pay for a fresh
// PhotoKit round-trip against the first candidate on every subsequent call.
- (NSString *)cachedPathForAsset:(PHAsset *)asset
                      candidates:(NSArray<PHAssetResource *> *)candidates
                        isOrigin:(BOOL)isOrigin
                        fileType:(AVFileType)fileType
             includeFallbackPath:(BOOL)includeFallbackPath {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    for (PHAssetResource *candidate in candidates) {
        NSString *path = [self makeAssetOutputPath:asset
                                          resource:candidate
                                          isOrigin:isOrigin
                                          fileType:fileType
                                           manager:fileManager];
        if ([fileManager fileExistsAtPath:path]) {
            [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
            return path;
        }
    }
    if (includeFallbackPath) {
        NSString *fallbackPath = [self makeAssetOutputPath:asset
                                                  resource:nil
                                                  isOrigin:isOrigin
                                                  fileType:fileType
                                                   manager:fileManager];
        if ([fileManager fileExistsAtPath:fallbackPath]) {
            [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", fallbackPath]];
            return fallbackPath;
        }
    }
    return nil;
}

// Compose the terminal error surfaced after every candidate resource fails.
// Preserves the last underlying NSError's domain/code (so callers keep seeing
// `PHPhotosErrorDomain (-1)` in their existing log matchers) while attaching
// the list of resource types we tried into the failure-reason field. That
// list is what surfaces as `PlatformException.details` on the Flutter side.
- (NSObject *)composeFetchError:(NSObject *)lastError
                          asset:(PHAsset *)asset
                      attempted:(NSArray<NSString *> *)attempted {
    NSString *attemptList = attempted.count > 0 ? [attempted componentsJoinedByString:@", "] : @"(none)";
    NSString *description = [NSString stringWithFormat:
                             @"Failed to export asset %@ after trying resources: [%@]",
                             asset.localIdentifier, attemptList];
    if ([lastError isKindOfClass:[NSError class]]) {
        NSError *err = (NSError *)lastError;
        NSMutableDictionary *userInfo = err.userInfo
            ? [NSMutableDictionary dictionaryWithDictionary:err.userInfo]
            : [NSMutableDictionary dictionary];
        if (!userInfo[NSLocalizedDescriptionKey]) {
            userInfo[NSLocalizedDescriptionKey] = description;
        }
        userInfo[NSLocalizedFailureReasonErrorKey] = description;
        return [NSError errorWithDomain:err.domain code:err.code userInfo:userInfo];
    }
    // Non-NSError underlying values (strings/exceptions from helper blocks)
    // or the no-error path (empty candidate list): always return an NSError
    // carrying the attempted-resource list, and stash the original value in
    // userInfo so Xcode logs can still surface whatever the helper produced.
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    userInfo[NSLocalizedFailureReasonErrorKey] = description;
    if (lastError) {
        userInfo[@"underlyingValue"] = [lastError description] ?: @"<non-NSError value>";
    }
    return [NSError errorWithDomain:@"PMPhotoManager" code:-1 userInfo:userInfo];
}

- (void)fetchVideoFileWithCandidates:(NSArray<PHAssetResource *> *)candidates
                               asset:(PHAsset *)asset
                     progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                          withScheme:(BOOL)withScheme
                            isOrigin:(BOOL)isOrigin
                            fileType:(AVFileType)fileType
                               block:(void (^)(NSString *path, NSObject *error))block {
    [self fetchVideoFileFromCandidates:candidates
                               atIndex:0
                             attempted:[NSMutableArray arrayWithCapacity:candidates.count]
                             lastError:nil
                                 asset:asset
                       progressHandler:progressHandler
                            withScheme:withScheme
                              isOrigin:isOrigin
                              fileType:fileType
                                 block:block];
}

- (void)fetchVideoFileFromCandidates:(NSArray<PHAssetResource *> *)candidates
                             atIndex:(NSUInteger)index
                           attempted:(NSMutableArray<NSString *> *)attempted
                           lastError:(NSObject *)lastError
                               asset:(PHAsset *)asset
                     progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                          withScheme:(BOOL)withScheme
                            isOrigin:(BOOL)isOrigin
                            fileType:(AVFileType)fileType
                               block:(void (^)(NSString *path, NSObject *error))block {
    if (index >= candidates.count) {
        block(nil, [self composeFetchError:lastError asset:asset attempted:attempted]);
        return;
    }
    PHAssetResource *resource = candidates[index];
    [attempted addObject:PMResourceTypeName(resource.type)];
    __weak typeof(self) weakSelf = self;
    [self fetchVideoResourceToFile:asset
                          resource:resource
                   progressHandler:progressHandler
                        withScheme:withScheme
                          isOrigin:isOrigin
                          fileType:fileType
                             block:^(NSString *path, NSObject *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (path) {
            block(path, nil);
            return;
        }
        [[PMLogUtils sharedInstance]
         info:[NSString stringWithFormat:@"Resource %@ failed for asset %@, trying next candidate. Error: %@",
               PMResourceTypeName(resource.type), asset.localIdentifier, error]];
        [strongSelf fetchVideoFileFromCandidates:candidates
                                         atIndex:index + 1
                                       attempted:attempted
                                       lastError:error
                                           asset:asset
                                 progressHandler:progressHandler
                                      withScheme:withScheme
                                        isOrigin:isOrigin
                                        fileType:fileType
                                           block:block];
    }];
}

- (void)fetchFullSizeVideo:(PHAsset *)asset
                   handler:(PMResultHandler *)handler
           progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                withScheme:(BOOL)withScheme
                  fileType:(AVFileType)fileType {
    [self exportAssetToFile:asset
            resultHandler:handler
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

// Fallback video fetch used when `writeDataForAssetResource` fails across every
// candidate resource. Goes through PHImageManager's requestAVAssetForVideo,
// which uses a different iCloud pipeline internally and often succeeds on
// assets the resource-level API refuses. Not usable for Live Photo paired
// videos (asset.mediaType is image), so only wire this into the plain-video
// entry point.
- (void)fallbackFetchVideoViaAVAsset:(PHAsset *)asset
                            isOrigin:(BOOL)isOrigin
                          withScheme:(BOOL)withScheme
                            fileType:(AVFileType)fileType
                     progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                               block:(void (^)(NSString *path, NSObject *error))block {
    if (!asset.isVideo) {
        // Live Photo (isImage=YES) and other non-video assets can't use this
        // API; refuse to run rather than get an opaque PhotoKit rejection.
        block(nil, [NSError errorWithDomain:@"PMPhotoManager" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"AVAsset fallback only applies to video assets."
        }]);
        return;
    }

    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset resource:nil isOrigin:isOrigin fileType:fileType manager:manager];
    if ([manager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        [self notifySuccess:progressHandler];
        block(withScheme ? [NSURL fileURLWithPath:path].absoluteString : path, nil);
        return;
    }

    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    [options setDeliveryMode:PHVideoRequestOptionsDeliveryModeHighQualityFormat];
    [options setNetworkAccessAllowed:YES];
    // Match the walker's rendered-first preference: if the caller asked for
    // the current version, the walker prefers the rendered/`fullSize`
    // resource, and this fallback should hit the same conceptual bytes.
    // `PHVideoRequestOptionsVersionCurrent` returns the edited AVComposition
    // for adjusted assets and the original file for unedited ones, so we
    // use it unconditionally. `isOrigin` is kept in the signature for
    // future opt-in ordering control but does not switch versions today.
    [options setVersion:PHVideoRequestOptionsVersionCurrent];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        [strongSelf.cachingManager
         requestAVAssetForVideo:asset
         options:options
         resultHandler:^(AVAsset *_Nullable avAsset,
                         AVAudioMix *_Nullable audioMix,
                         NSDictionary *_Nullable info) {
            __strong typeof(weakSelf) innerSelf = weakSelf;
            if (!innerSelf) { return; }
            NSObject *error = info[PHImageErrorKey];
            if (error) {
                block(nil, error);
                return;
            }
            if (![PMManager isDownloadFinish:info]) {
                return;
            }
            if ([avAsset isKindOfClass:[AVURLAsset class]]) {
                AVURLAsset *urlAsset = (AVURLAsset *)avAsset;
                NSURL *videoURL = urlAsset.URL;
                NSURL *destination = [NSURL fileURLWithPath:path];
                if ([videoURL.path isEqualToString:destination.path]) {
                    [innerSelf notifySuccess:progressHandler];
                    block(withScheme ? videoURL.absoluteString : videoURL.path, nil);
                    return;
                }
                // `copyItemAtURL:toURL:` fails with NSFileWriteFileExistsError
                // when the destination already has a stub from a prior aborted
                // fetch. Match the guard `exportAssetToFile` uses on iOS 18.
                if ([manager fileExistsAtPath:destination.path]) {
                    [innerSelf notifySuccess:progressHandler];
                    block(withScheme ? destination.absoluteString : path, nil);
                    return;
                }
                NSError *copyError;
                [manager copyItemAtURL:videoURL toURL:destination error:&copyError];
                if (copyError) {
                    block(nil, copyError);
                    return;
                }
                [innerSelf notifySuccess:progressHandler];
                block(withScheme ? destination.absoluteString : path, nil);
                return;
            }
            // AVComposition (adjusted asset) — export session handles it.
            // Note: `exportAVAssetToFile` already applies the withScheme
            // wrap when writing back, so we return its `exportedPath`
            // verbatim to avoid a `file:///file:///…` double-wrap.
            [innerSelf exportAVAssetToFile:avAsset
                              destination:path
                          progressHandler:progressHandler
                               withScheme:withScheme
                                 fileType:fileType
                                    block:^(NSString *exportedPath, NSObject *exportError) {
                block(exportedPath, exportedPath ? nil : exportError);
            }];
        }];
    });
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
    // `Prepare` is emitted once from the caller so multi-candidate walks don't
    // bounce progress observers back to 0 between attempts.
    __weak typeof(self) weakSelf = self;
    [options setProgressHandler:^(double progress) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        lastProgress = progress;
        if (progress != 1) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    
    PHAssetResourceManager *resourceManager = PHAssetResourceManager.defaultManager;
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    [resourceManager writeDataForAssetResource:resource
                                        toFile:fileUrl
                                       options:options
                             completionHandler:^(NSError *_Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            // Don't emit Failed here — the walker may retry with another
            // candidate and only the terminal outcome should surface as a
            // failure state to progress observers.
            block(nil, error);
            return;
        }
        if (fileType) {
            NSString *newPath = [strongSelf makeAssetOutputPath:asset
                                              resource:resource
                                              isOrigin:isOrigin
                                              fileType:fileType
                                               manager:fileManager];
            [strongSelf exportAVAssetToFile:[AVAsset assetWithURL:[NSURL fileURLWithPath:path]]
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
        [strongSelf notifySuccess:progressHandler];
        if (withScheme) {
            block([NSURL fileURLWithPath:path].absoluteString, nil);
        } else {
            block(path, nil);
        }
    }];
}

- (void)exportAssetToFile:(PHAsset *)asset
          resultHandler:(PMResultHandler *)handler
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
    __weak typeof(self) weakSelf = self;
    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        lastProgress = progress;
        if (error) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            return;
        }
        if (progress != 1) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    
    // PHImageManager methods must be called on the main thread to avoid crashes
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        PHImageRequestID requestId = [strongSelf.cachingManager
         requestAVAssetForVideo:asset
         options:options
         resultHandler:^(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info) {
            __strong typeof(weakSelf) innerStrongSelf = weakSelf;
            if (!innerStrongSelf) {
                return;
            }
            
            NSObject *error = info[PHImageErrorKey];
            if (error) {
                [innerStrongSelf notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
                block(nil, error);
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
                return;
            }
            
            BOOL downloadFinished = [PMManager isDownloadFinish:info];
            if (!downloadFinished) {
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
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
                    [innerStrongSelf notifySuccess:progressHandler];
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
                    [innerStrongSelf notifySuccess:progressHandler];
                    return;
                }
                [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"Caching the video to %@", destination]];
                [[NSFileManager defaultManager] copyItemAtURL:videoURL
                                                        toURL:destination
                                                        error:&error];
                if (error) {
                    block(nil, error);
                    [innerStrongSelf notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
                    return;
                }
                if (withScheme) {
                    block(destination.absoluteString, nil);
                } else {
                    block(path, nil);
                }
                [innerStrongSelf notifySuccess:progressHandler];
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
                return;
            }
            
            [innerStrongSelf exportAVAssetToFile:asset
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
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
            }];
        }];

        [strongSelf addRequstId:[handler getCancelToken] requestId:requestId];
    });
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
    NSString *filename;
    if (resource) {
        filename = resource.originalFilename;
    } else {
        filename = [asset title];
    }
    NSString *fallbackExtension = [filename pathExtension];
    if (resource && [fallbackExtension isEmpty]) {
        fallbackExtension = [[asset title] pathExtension];
    }
    
    // Determine the target extension before building the timestamped filename so
    // that the dot embedded in the %f timestamp format does not cause pathExtension
    // to return a bogus fractional-seconds value instead of triggering the fallback.
    NSString *targetExtension = fallbackExtension;
    if (fileType) {
        NSString *newExtension = [PMConvertUtils convertAVFileTypeToExtension:fileType];
        if (newExtension) {
            targetExtension = [newExtension stringByReplacingOccurrencesOfString:@"." withString:@""];
        }
    }

    NSString *id = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *modifiedDate = [NSString stringWithFormat:@"%f", asset.modificationDate.timeIntervalSince1970];
    NSString *filenameBase = [filename stringByDeletingPathExtension];
    filename = [NSString stringWithFormat:@"%@_%@%@_%@",
                id, modifiedDate, isOrigin ? @"_o" : @"", filenameBase];
    if (![targetExtension isEmpty]) {
        filename = [filename stringByAppendingPathExtension:targetExtension];
    }
    
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
    
    NSString *homePath = NSTemporaryDirectory();
    NSMutableString *path = [NSMutableString stringWithString:homePath];
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

- (void)fetchOriginImageFile:(PHAsset *)asset resultHandler:(PMResultHandler *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    NSArray<PHAssetResource *> *candidates = [asset candidateResourcesForFetch:YES livePhoto:NO];
    if (candidates.count == 0) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ does not have available resources.", asset.localIdentifier]];
        return;
    }
    NSString *cached = [self cachedPathForAsset:asset
                                     candidates:candidates
                                       isOrigin:YES
                                       fileType:nil
                            includeFallbackPath:YES];
    if (cached) {
        [self notifySuccess:progressHandler];
        [handler reply:cached];
        return;
    }
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    __weak typeof(self) weakSelf = self;
    [self fetchImageFileFromCandidates:candidates
                               atIndex:0
                             attempted:[NSMutableArray arrayWithCapacity:candidates.count]
                             lastError:nil
                                 asset:asset
                       progressHandler:progressHandler
                                 block:^(NSString *path, NSObject *walkerError) {
        if (path) {
            [handler reply:path];
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        // Every candidate resource failed. Fall back to PHImageManager's
        // requestImageDataAndOrientation pipeline, which is a separate iCloud
        // materialization path and preserves the original HEIC/RAW bytes.
        [strongSelf fallbackFetchImageDataFor:asset
                                     isOrigin:YES
                              progressHandler:progressHandler
                                        block:^(NSString *fbPath, NSObject *fbError) {
            if (fbPath) {
                [handler reply:fbPath];
                return;
            }
            [strongSelf notifyProgress:progressHandler progress:0 state:PMProgressStateFailed];
            [handler replyError:walkerError ?: fbError];
        }];
    }];
}

- (void)fetchImageFileFromCandidates:(NSArray<PHAssetResource *> *)candidates
                             atIndex:(NSUInteger)index
                           attempted:(NSMutableArray<NSString *> *)attempted
                           lastError:(NSObject *)lastError
                               asset:(PHAsset *)asset
                     progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                               block:(void (^)(NSString *path, NSObject *error))block {
    if (index >= candidates.count) {
        block(nil, [self composeFetchError:lastError asset:asset attempted:attempted]);
        return;
    }
    PHAssetResource *resource = candidates[index];
    [attempted addObject:PMResourceTypeName(resource.type)];
    __weak typeof(self) weakSelf = self;
    [self writeImageResourceToFile:resource
                             asset:asset
                   progressHandler:progressHandler
                             block:^(NSString *path, NSObject *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (path) {
            block(path, nil);
            return;
        }
        [[PMLogUtils sharedInstance]
         info:[NSString stringWithFormat:@"Resource %@ failed for asset %@, trying next candidate. Error: %@",
               PMResourceTypeName(resource.type), asset.localIdentifier, error]];
        [strongSelf fetchImageFileFromCandidates:candidates
                                         atIndex:index + 1
                                       attempted:attempted
                                       lastError:error
                                           asset:asset
                                 progressHandler:progressHandler
                                           block:block];
    }];
}

- (void)writeImageResourceToFile:(PHAssetResource *)imageResource
                           asset:(PHAsset *)asset
                 progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                           block:(void (^)(NSString *path, NSObject *error))block {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset
                                      resource:imageResource
                                      isOrigin:YES
                                      fileType:nil
                                       manager:fileManager];
    if ([fileManager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        block(path, nil);
        return;
    }

    PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
    [options setNetworkAccessAllowed:YES];

    __block double lastProgress = 0.0;
    // `Prepare` is emitted once from the caller so multi-candidate walks don't
    // bounce progress observers back to 0 between attempts.
    __weak typeof(self) weakSelf = self;
    [options setProgressHandler:^(double progress) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        lastProgress = progress;
        if (progress != 1) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];

    PHAssetResourceManager *resourceManager = PHAssetResourceManager.defaultManager;
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    [resourceManager writeDataForAssetResource:imageResource
                                        toFile:fileUrl
                                       options:options
                             completionHandler:^(NSError *_Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            // Walker retries with the next candidate; don't emit Failed here.
            block(nil, error);
        } else {
            [strongSelf notifySuccess:progressHandler];
            block(path, nil);
        }
    }];
}

// Fallback image fetch used when `writeDataForAssetResource` fails across
// every candidate resource. Uses PHImageManager's data pipeline, which is a
// separate iCloud-materialization path and returns the raw image bytes so we
// can write them verbatim without a JPEG recompression.
- (void)fallbackFetchImageDataFor:(PHAsset *)asset
                         isOrigin:(BOOL)isOrigin
                  progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler
                            block:(void (^)(NSString *path, NSObject *error))block {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *path = [self makeAssetOutputPath:asset resource:nil isOrigin:isOrigin fileType:nil manager:manager];
    if ([manager fileExistsAtPath:path]) {
        [[PMLogUtils sharedInstance] info:[NSString stringWithFormat:@"read cache from %@", path]];
        [self notifySuccess:progressHandler];
        block(path, nil);
        return;
    }

    PHImageRequestOptions *options = [PHImageRequestOptions new];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
    [options setNetworkAccessAllowed:YES];
    [options setSynchronous:NO];
    // Match the walker's rendered-first preference (see the equivalent note
    // on `fallbackFetchVideoViaAVAsset`).
    [options setVersion:PHImageRequestOptionsVersionCurrent];

    __weak typeof(self) weakSelf = self;
    [options setProgressHandler:^(double progress, NSError *progressError, BOOL *stop, NSDictionary *info) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (progressError) { return; }
        if (progress != 1) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];

    void (^dataHandler)(NSData *_Nullable, NSDictionary *_Nullable) = ^(NSData *_Nullable imageData, NSDictionary *_Nullable info) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        NSObject *error = info[PHImageErrorKey];
        if (error) {
            block(nil, error);
            return;
        }
        if (!imageData) {
            block(nil, [NSError errorWithDomain:@"PMPhotoManager" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"PHImageManager returned no image data."
            }]);
            return;
        }
        NSError *writeError;
        [imageData writeToFile:path options:NSDataWritingAtomic error:&writeError];
        if (writeError) {
            block(nil, writeError);
            return;
        }
        [strongSelf notifySuccess:progressHandler];
        block(path, nil);
    };

    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (@available(iOS 13.0, macOS 10.15, *)) {
            [strongSelf.cachingManager requestImageDataAndOrientationForAsset:asset
                                                                     options:options
                                                               resultHandler:^(NSData *_Nullable imageData,
                                                                               NSString *_Nullable dataUTI,
                                                                               CGImagePropertyOrientation orientation,
                                                                               NSDictionary *_Nullable info) {
                dataHandler(imageData, info);
            }];
        } else {
#if TARGET_OS_IOS
            [strongSelf.cachingManager requestImageDataForAsset:asset
                                                        options:options
                                                  resultHandler:^(NSData *_Nullable imageData,
                                                                  NSString *_Nullable dataUTI,
                                                                  UIImageOrientation orientation,
                                                                  NSDictionary *_Nullable info) {
                dataHandler(imageData, info);
            }];
#else
            dataHandler(nil, @{PHImageErrorKey: [NSError errorWithDomain:@"PMPhotoManager" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"requestImageDataForAsset unavailable on this platform version."
            }]});
#endif
        }
    });
}

- (void)fetchFullSizeImageFile:(PHAsset *)asset
                 resultHandler:(PMResultHandler *)handler
               progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
    [options setNetworkAccessAllowed:YES];
    [options setResizeMode:PHImageRequestOptionsResizeModeNone];
    [options setSynchronous:NO];
    [options setVersion:PHImageRequestOptionsVersionCurrent];
    
    __block double lastProgress = 0.0;
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    __weak typeof(self) weakSelf = self;
    [options setProgressHandler:^(double progress, NSError *error, BOOL *stop,
                                  NSDictionary *info) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateFailed];
            return;
        }
        lastProgress = progress;
        if (progress != 1) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];
    
    // PHImageManager methods must be called on the main thread to avoid crashes
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        PHImageRequestID requestId = [strongSelf.cachingManager requestImageForAsset:asset
                                       targetSize:PHImageManagerMaximumSize
                                      contentMode:PHImageContentModeDefault
                                          options:options
                                    resultHandler:^(PMImage *_Nullable image, NSDictionary *_Nullable info) {
            __strong typeof(weakSelf) innerStrongSelf = weakSelf;
            if (!innerStrongSelf) {
                return;
            }
            
            if ([handler isReplied]) {
                return;
            }
            
            PHImageRequestID currentReqID = [[info objectForKey:PHImageResultRequestIDKey] intValue];
            
            if (currentReqID == PHInvalidImageRequestID) {
                [handler replyError:@"Failed to fetch full size image."];
                [innerStrongSelf notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
                return;
            }
            
            NSObject *error = info[PHImageErrorKey];
            if (error) {
                [handler replyError:error];
                [innerStrongSelf notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
                return;
            }

            if ([info[PHImageCancelledKey] boolValue]) {
                [innerStrongSelf handleCancelRequest:handler progressHandler:progressHandler];
                [innerStrongSelf removeRequstIdWithCancelToken:[handler getCancelToken]];
                return;
            }

            if ([info[PHImageResultIsDegradedKey] boolValue]) {
                return;
            }

            NSString *cancelToken = [handler getCancelToken];
            dispatch_async(innerStrongSelf->_imageFileProcessingQueue, ^{
                // Drop the result if the request was cancelled while we were waiting.
                if (![innerStrongSelf isRequestActiveWithCancelToken:cancelToken]) {
                    [innerStrongSelf handleCancelRequestIfNeeded:handler progressHandler:progressHandler];
                    return;
                }
                NSData *data = [PMImageUtil convertToData:image formatType:PMThumbFormatTypeJPEG quality:1.0];
                if (data) {
                    NSString *path = [innerStrongSelf writeFullFileWithAssetId:asset imageData:data];
                    if (![innerStrongSelf consumeRequestWithCancelToken:cancelToken]) {
                        [innerStrongSelf handleCancelRequestIfNeeded:handler progressHandler:progressHandler];
                        return;
                    }
                    [handler reply:path];
                    [innerStrongSelf notifySuccess:progressHandler];
                } else {
                    if (![innerStrongSelf consumeRequestWithCancelToken:cancelToken]) {
                        [innerStrongSelf handleCancelRequestIfNeeded:handler progressHandler:progressHandler];
                        return;
                    }
                    [handler replyError:[NSString stringWithFormat:@"Failed to convert %@ to a JPEG file.", asset.localIdentifier]];
                    [innerStrongSelf notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
                }
            });
        }];

        [strongSelf addRequstId:[handler getCancelToken] requestId:requestId];
    });
}

+ (BOOL)isDownloadFinish:(NSDictionary *)info {
    return ![info[PHImageCancelledKey] boolValue] && ![info[PHImageResultIsDegradedKey] boolValue];
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
    if (optionGroup) {
        return [optionGroup getFetchOptions:type];
    }
    
    return [PMRequestTypeUtils getFetchOptionsByType:type];
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

#if TARGET_OS_OSX

+ (void)openSetting:(PMResultHandler*)result {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c" , @"open x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"];
    [task launch];
    [result reply:@true];
}

#endif

#if TARGET_OS_IOS

+ (void)openSetting:(PMResultHandler*)result {
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
    PHFetchOptions *options = [PHFetchOptions new];
    options.fetchLimit = ids.count;
    PHFetchResult<PHAsset *> *result = [self fetchAssetsWithLocalIdentifiersSafely:ids
                                                                           options:options
                                                                         operation:@"deleteWithIds"];
    if (!result) {
        block(@[]);
        return;
    }

    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
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
         latitude:(NSNumber *)latitude
        longitude:(NSNumber *)longitude
     creationDate:(NSNumber *)creationDate
            block:(AssetBlockResult)block {
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Saving image with data, length: %lu, filename: %@, desc: %@", (unsigned long)data.length, filename, desc]];

    __block NSString *assetId = nil;
    __weak typeof(self) weakSelf = self;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        [options setOriginalFilename:filename];
        [request addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
        
        // Set location if provided
        if (![latitude isNilOrNull] && ![longitude isNilOrNull]) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
            [request setLocation:location];
        }
        
        // Set creation date if provided
        if (![creationDate isNilOrNull]) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[creationDate doubleValue] / 1000.0];
            [request setCreationDate:date];
        }
        
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Created image %@", assetId]];
            block([strongSelf getAssetEntity:assetId], nil);
        } else {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Save image with data failed %@, reason = %@", assetId, error]];
            block(nil, error);
        }
    }];
}

- (void)saveImageWithPath:(NSString *)path
                 filename:(NSString *)filename
                     desc:(NSString *)desc
                 latitude:(NSNumber *)latitude
                longitude:(NSNumber *)longitude
             creationDate:(NSNumber *)creationDate
                    block:(AssetBlockResult)block {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        block(nil, [NSString stringWithFormat:@"File does not exist at %@", path]);
        return;
    }

    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Saving image with path: %@ filename: %@, desc: %@", path, filename, desc]];
    
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    __block NSString *assetId = nil;
    __weak typeof(self) weakSelf = self;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        if (filename) {
            [options setOriginalFilename:filename];
        }
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:fileURL options:options];
        
        // Set location if provided
        if (![latitude isNilOrNull] && ![longitude isNilOrNull]) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
            [request setLocation:location];
        }
        
        // Set creation date if provided
        if (![creationDate isNilOrNull]) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[creationDate doubleValue] / 1000.0];
            [request setCreationDate:date];
        }
        
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
            block([strongSelf getAssetEntity:assetId], nil);
        } else {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Save image with path failed %@, reason = %@", assetId, error]];
            block(nil, error);
        }
    }];
}

- (void)saveVideo:(NSString *)path
         filename:(NSString *)filename
             desc:(NSString *)desc
         latitude:(NSNumber *)latitude
        longitude:(NSNumber *)longitude
     creationDate:(NSNumber *)creationDate
            block:(AssetBlockResult)block {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        block(nil, [NSString stringWithFormat:@"File does not exist at %@", path]);
        return;
    }

    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Saving video with path: %@, filename: %@, desc %@", path, filename, desc]];

    NSURL *fileURL = [NSURL fileURLWithPath:path];
    __block NSString *assetId = nil;
    __weak typeof(self) weakSelf = self;
    [[PHPhotoLibrary sharedPhotoLibrary]
     performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        if (filename) {
            [options setOriginalFilename:filename];
        }
        [request addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:options];
        
        // Set location if provided
        if (![latitude isNilOrNull] && ![longitude isNilOrNull]) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
            [request setLocation:location];
        }
        
        // Set creation date if provided
        if (![creationDate isNilOrNull]) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[creationDate doubleValue] / 1000.0];
            [request setCreationDate:date];
        }
        
        assetId = request.placeholderForCreatedAsset.localIdentifier;
    }
     completionHandler:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (success) {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"create asset : id = %@", assetId]];
            block([strongSelf getAssetEntity:assetId], nil);
        } else {
            [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"Save video with path failed %@, reason = %@", assetId, error]];
            block(nil, error);
        }
    }];
}

#pragma mark - Live Photo Metadata Helpers

// Live Photos require the still image and paired video to share a
// `com.apple.quicktime.content.identifier` UUID. When callers hand us plain
// HEIC/JPEG + MOV/MP4 the Photos framework rejects the resource pair with
// PHPhotosErrorDomain -1. These helpers inject the identifier into both files
// (image via `kCGImagePropertyMakerAppleDictionary["17"]`, video via a
// QuickTime metadata item + a still-image-time metadata track) before we
// submit the creation request. Reference: https://github.com/LimitPoint/LivePhoto
//
// `sourceType` (out) receives the source image's UTI so the caller can set
// `PHAssetResourceCreationOptions.uniformTypeIdentifier` accurately.
- (NSURL *)addLivePhotoAssetIdentifier:(NSString *)assetIdentifier
                                  desc:(NSString *)desc
                          toImageAtURL:(NSURL *)imageURL
                             outputURL:(NSURL *)outputURL
                            sourceUTI:(NSString **)sourceUTIOut {
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, nil);
    if (!imageSource) {
        [PMLogUtils.sharedInstance info:@"[LivePhoto][Meta] Failed to create image source"];
        return nil;
    }
    CFStringRef sourceType = CGImageSourceGetType(imageSource);
    if (!sourceType) {
        CFRelease(imageSource);
        [PMLogUtils.sharedInstance info:@"[LivePhoto][Meta] Failed to determine source image type"];
        return nil;
    }
    if (sourceUTIOut) {
        // Copy the string — CGImageSourceGetType returns a CFStringRef whose
        // lifetime is tied to the source, which we release below.
        *sourceUTIOut = [NSString stringWithString:(__bridge NSString *)sourceType];
    }
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL(
        (__bridge CFURLRef)outputURL, sourceType, 1, nil);
    if (!imageDestination) {
        CFRelease(imageSource);
        [PMLogUtils.sharedInstance info:@"[LivePhoto][Meta] Failed to create image destination"];
        return nil;
    }
    NSDictionary *srcProps = (__bridge_transfer NSDictionary *)
        CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
    NSMutableDictionary *props = srcProps ? [srcProps mutableCopy]
                                          : [NSMutableDictionary dictionary];
    props[(__bridge NSString *)kCGImagePropertyMakerAppleDictionary] =
        @{ @"17" : assetIdentifier };
    if (![desc isNilOrNull] && desc.length > 0) {
        NSString *tiffKey = (__bridge NSString *)kCGImagePropertyTIFFDictionary;
        NSString *tiffDescKey = (__bridge NSString *)kCGImagePropertyTIFFImageDescription;
        NSMutableDictionary *tiff = props[tiffKey] ? [props[tiffKey] mutableCopy]
                                                   : [NSMutableDictionary dictionary];
        tiff[tiffDescKey] = desc;
        props[tiffKey] = tiff;
    }
    // Streams encoded bytes through — no CG decode/re-encode.
    CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0,
                                         (__bridge CFDictionaryRef)props);
    BOOL ok = CGImageDestinationFinalize(imageDestination);
    CFRelease(imageSource);
    CFRelease(imageDestination);
    if (!ok) {
        [PMLogUtils.sharedInstance info:@"[LivePhoto][Meta] CGImageDestinationFinalize failed"];
        return nil;
    }
    return outputURL;
}

- (void)addLivePhotoAssetIdentifier:(NSString *)assetIdentifier
                       toVideoAtURL:(NSURL *)videoURL
                          outputURL:(NSURL *)outputURL
                         completion:(void (^)(NSURL *resultURL, NSError *error))completion {
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    NSArray<AVAssetTrack *> *videoTracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count == 0) {
        completion(nil, [NSError errorWithDomain:@"PMManager" code:-1
                                       userInfo:@{NSLocalizedDescriptionKey: @"No video track found in source file"}]);
        return;
    }
    AVAssetTrack *videoTrack = videoTracks.firstObject;

    NSError *error = nil;
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outputURL
                                                         fileType:AVFileTypeQuickTimeMovie
                                                            error:&error];
    if (error || !assetWriter) {
        completion(nil, error);
        return;
    }

    AVAssetReader *videoReader = [[AVAssetReader alloc] initWithAsset:videoAsset error:&error];
    if (error || !videoReader) {
        completion(nil, error);
        return;
    }
    AVAssetReaderTrackOutput *videoReaderOutput =
        [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                  outputSettings:nil];
    [videoReader addOutput:videoReaderOutput];

    CMFormatDescriptionRef videoFmt =
        (__bridge CMFormatDescriptionRef)videoTrack.formatDescriptions.firstObject;
    AVAssetWriterInput *videoWriterInput =
        [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                          outputSettings:nil
                                        sourceFormatHint:videoFmt];
    videoWriterInput.transform = videoTrack.preferredTransform;
    videoWriterInput.expectsMediaDataInRealTime = NO;
    [assetWriter addInput:videoWriterInput];

    AVAssetReader *audioReader = nil;
    AVAssetReaderTrackOutput *audioReaderOutput = nil;
    AVAssetWriterInput *audioWriterInput = nil;
    NSArray<AVAssetTrack *> *audioTracks = [videoAsset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count > 0) {
        AVAssetTrack *audioTrack = audioTracks.firstObject;
        audioReader = [[AVAssetReader alloc] initWithAsset:videoAsset error:&error];
        if (!error && audioReader) {
            audioReaderOutput =
                [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack
                                                         outputSettings:nil];
            [audioReader addOutput:audioReaderOutput];
            audioWriterInput =
                [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                  outputSettings:nil];
            audioWriterInput.expectsMediaDataInRealTime = NO;
            [assetWriter addInput:audioWriterInput];
        }
    }

    AVMutableMetadataItem *identifierItem = [AVMutableMetadataItem metadataItem];
    identifierItem.key = @"com.apple.quicktime.content.identifier";
    identifierItem.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    identifierItem.value = assetIdentifier;
    identifierItem.dataType = @"com.apple.metadata.datatype.UTF-8";
    assetWriter.metadata = @[identifierItem];

    NSString *keyStillImageTime = @"com.apple.quicktime.still-image-time";
    NSDictionary *spec = @{
        (__bridge NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier :
            [NSString stringWithFormat:@"mdta/%@", keyStillImageTime],
        (__bridge NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType :
            @"com.apple.metadata.datatype.int8"
    };
    CMFormatDescriptionRef metaFmtDesc = NULL;
    CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
        kCFAllocatorDefault, kCMMetadataFormatType_Boxed,
        (__bridge CFArrayRef)@[spec], &metaFmtDesc);
    AVAssetWriterInput *metadataWriterInput =
        [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata
                                          outputSettings:nil
                                        sourceFormatHint:metaFmtDesc];
    AVAssetWriterInputMetadataAdaptor *metadataAdaptor =
        [AVAssetWriterInputMetadataAdaptor
            assetWriterInputMetadataAdaptorWithAssetWriterInput:metadataWriterInput];
    [assetWriter addInput:metadataWriterInput];
    if (metaFmtDesc) {
        CFRelease(metaFmtDesc);
    }

    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];

    AVMutableMetadataItem *stillItem = [AVMutableMetadataItem metadataItem];
    stillItem.key = keyStillImageTime;
    stillItem.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    stillItem.value = @0;
    stillItem.dataType = @"com.apple.metadata.datatype.int8";
    CMTime duration = videoAsset.duration;
    CMTime midPoint = CMTimeMake(duration.value / 2, duration.timescale);
    Float64 fps = videoTrack.nominalFrameRate;
    // Round up so fractional fps (time-lapse, slow-mo variants) doesn't
    // truncate to zero and crash the CMTimeMake divide below.
    int32_t fpsInt = fps >= 1.0 ? (int32_t)ceil(fps) : 30;
    CMTime frameDur = CMTimeMake(duration.timescale / fpsInt, duration.timescale);
    CMTimeRange stillRange = CMTimeRangeMake(midPoint, frameDur);
    AVTimedMetadataGroup *metaGroup =
        [[AVTimedMetadataGroup alloc] initWithItems:@[stillItem] timeRange:stillRange];
    if (![metadataAdaptor appendTimedMetadataGroup:metaGroup]) {
        [PMLogUtils.sharedInstance info:@"[LivePhoto][Meta] Failed to append still-image-time metadata group"];
    }
    [metadataWriterInput markAsFinished];

    dispatch_group_t doneGroup = dispatch_group_create();
    dispatch_queue_t videoQueue = dispatch_queue_create("com.fluttercandies.pm.livePhotoVideoQueue", NULL);
    dispatch_queue_t audioQueue = dispatch_queue_create("com.fluttercandies.pm.livePhotoAudioQueue", NULL);

    dispatch_group_enter(doneGroup);
    if ([videoReader startReading]) {
        [videoWriterInput requestMediaDataWhenReadyOnQueue:videoQueue usingBlock:^{
            // Keep videoReader alive until the block finishes — the output
            // holds only an unowned reference back to its reader, so if the
            // outer function's strong ref goes out of scope before the block
            // runs, copyNextSampleBuffer will throw
            // "output not added to a reader".
            (void)videoReader;
            while (videoWriterInput.readyForMoreMediaData) {
                CMSampleBufferRef buf = [videoReaderOutput copyNextSampleBuffer];
                if (buf) {
                    [videoWriterInput appendSampleBuffer:buf];
                    CFRelease(buf);
                } else {
                    [videoWriterInput markAsFinished];
                    dispatch_group_leave(doneGroup);
                    return;
                }
            }
        }];
    } else {
        [videoWriterInput markAsFinished];
        dispatch_group_leave(doneGroup);
    }

    if (audioWriterInput && audioReader) {
        dispatch_group_enter(doneGroup);
        if ([audioReader startReading]) {
            [audioWriterInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^{
                (void)audioReader;
                while (audioWriterInput.readyForMoreMediaData) {
                    CMSampleBufferRef buf = [audioReaderOutput copyNextSampleBuffer];
                    if (buf) {
                        [audioWriterInput appendSampleBuffer:buf];
                        CFRelease(buf);
                    } else {
                        [audioWriterInput markAsFinished];
                        dispatch_group_leave(doneGroup);
                        return;
                    }
                }
            }];
        } else {
            [audioWriterInput markAsFinished];
            dispatch_group_leave(doneGroup);
        }
    }

    dispatch_group_notify(doneGroup, dispatch_get_main_queue(), ^{
        [assetWriter finishWritingWithCompletionHandler:^{
            if (assetWriter.status == AVAssetWriterStatusCompleted) {
                completion(outputURL, nil);
            } else {
                completion(nil, assetWriter.error);
            }
        }];
    });
}

- (void)saveLivePhoto:(NSString *)imagePath
            videoPath:(NSString *)videoPath
                title:(NSString *)title
                 desc:(NSString *)desc
                block:(AssetBlockResult)block {
    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Saving Live Photo with imagePath: %@, videoPath: %@, filename: %@, desc: %@", imagePath, videoPath, title, desc]];

    NSFileManager *fm = NSFileManager.defaultManager;
    if (![fm fileExistsAtPath:imagePath]) {
        block(nil, [NSError errorWithDomain:@"PMManager" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Image file does not exist at path: %@", imagePath]
        }]);
        return;
    }
    if (![fm fileExistsAtPath:videoPath]) {
        block(nil, [NSError errorWithDomain:@"PMManager" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Video file does not exist at path: %@", videoPath]
        }]);
        return;
    }

    NSString *assetIdentifier = [[NSUUID UUID] UUIDString];
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"pm_livephoto"];
    [fm createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *imageExt = imagePath.pathExtension.length > 0 ? imagePath.pathExtension : @"jpg";
    // Paired Live Photo video is always QuickTime .mov — Photos rejects
    // other containers even if the source was MP4/HEVC.
    NSString *videoExt = @"mov";
    NSURL *srcImageURL = [NSURL fileURLWithPath:imagePath];
    NSURL *srcVideoURL = [NSURL fileURLWithPath:videoPath];
    NSURL *tmpImageURL = [NSURL fileURLWithPath:
        [[tmpDir stringByAppendingPathComponent:assetIdentifier] stringByAppendingPathExtension:imageExt]];
    NSURL *tmpVideoURL = [NSURL fileURLWithPath:
        [[tmpDir stringByAppendingPathComponent:assetIdentifier] stringByAppendingPathExtension:videoExt]];
    [fm removeItemAtURL:tmpImageURL error:nil];
    [fm removeItemAtURL:tmpVideoURL error:nil];

    NSString *imageUTI = nil;
    NSURL *enrichedImageURL = [self addLivePhotoAssetIdentifier:assetIdentifier
                                                           desc:desc
                                                  toImageAtURL:srcImageURL
                                                     outputURL:tmpImageURL
                                                     sourceUTI:&imageUTI];
    if (!enrichedImageURL) {
        block(nil, [NSError errorWithDomain:@"PMManager" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"Failed to write Live Photo metadata to image file"
        }]);
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self addLivePhotoAssetIdentifier:assetIdentifier
                         toVideoAtURL:srcVideoURL
                            outputURL:tmpVideoURL
                           completion:^(NSURL *enrichedVideoURL, NSError *videoError) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (!enrichedVideoURL) {
            [fm removeItemAtURL:tmpImageURL error:nil];
            // AVAssetWriter may have written a partial file before failing.
            [fm removeItemAtURL:tmpVideoURL error:nil];
            block(nil, videoError ?: [NSError errorWithDomain:@"PMManager" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to write Live Photo metadata to video file"
            }]);
            return;
        }

        PHAssetResourceCreationOptions *imageOptions = [PHAssetResourceCreationOptions new];
        PHAssetResourceCreationOptions *videoOptions = [PHAssetResourceCreationOptions new];
        if (imageUTI.length > 0) {
            imageOptions.uniformTypeIdentifier = imageUTI;
        }
        videoOptions.uniformTypeIdentifier = AVFileTypeQuickTimeMovie;
        if (![title isNilOrNull] && title.length > 0) {
            NSString *baseTitle = title.stringByDeletingPathExtension;
            [imageOptions setOriginalFilename:[baseTitle stringByAppendingPathExtension:imageExt]];
            [videoOptions setOriginalFilename:[baseTitle stringByAppendingPathExtension:videoExt]];
        }

        __block NSString *assetId = nil;
        [[PHPhotoLibrary sharedPhotoLibrary]
         performChanges:^{
            PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
            [request addResourceWithType:PHAssetResourceTypePhoto fileURL:enrichedImageURL options:imageOptions];
            [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:enrichedVideoURL options:videoOptions];
            assetId = request.placeholderForCreatedAsset.localIdentifier;
        }
         completionHandler:^(BOOL success, NSError *saveError) {
            [fm removeItemAtURL:tmpImageURL error:nil];
            [fm removeItemAtURL:tmpVideoURL error:nil];
            if (success) {
                [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Created Live Photo asset = %@", assetId]];
                // Warn (don't fail) if Photos accepted the pair but didn't
                // classify it as a Live Photo — indicates the metadata was
                // ignored and the pair was flattened to a still + video.
                PHFetchResult *r = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil];
                PHAsset *created = r.firstObject;
                if (created && (created.mediaSubtypes & PHAssetMediaSubtypePhotoLive) == 0) {
                    [PMLogUtils.sharedInstance info:[NSString stringWithFormat:
                        @"[LivePhoto] WARNING: saved asset %@ was NOT recognized as Live Photo (mediaSubtypes=%lu)",
                        assetId, (unsigned long)created.mediaSubtypes]];
                }
                block([strongSelf getAssetEntity:assetId], nil);
            } else {
                [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"Create Live Photo asset failed = %@, %@", assetId, saveError]];
                block(nil, saveError);
            }
        }];
    }];
}

- (void)getDurationWithOptions:(NSString *)assetId
                       subtype:(int)subtype
                 resultHandler:(PMResultHandler *)handler {
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
            [handler reply:@([PMConvertUtils roundDurationSeconds:time])];
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
    PHFetchResult *fetchResult = [self fetchAssetsWithLocalIdentifiersSafely:@[assetId]
                                                                     options:[self singleFetchOptions]
                                                                   operation:@"getTitleAsyncWithAssetId"];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (asset) {
        return [asset filenameWithOptions:subtype isOrigin:isOrigin fileType:fileType];
    }
    return @"";
}

- (NSUInteger)getFileSizeWithAssetId:(NSString *)assetId {
    PHFetchResult *fetchResult = [self fetchAssetsWithLocalIdentifiersSafely:@[assetId]
                                                                     options:[self singleFetchOptions]
                                                                   operation:@"getFileSizeWithAssetId"];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (!asset) {
        return 0;
    }
    PHAssetResource *resource = [asset getCurrentResource];
    if (!resource) {
        return 0;
    }
    @try {
        NSNumber *fileSize = [resource valueForKey:@"fileSize"];
        if (![fileSize isKindOfClass:NSNumber.class]) {
            return 0;
        }
        return fileSize.unsignedIntegerValue;
    } @catch (NSException *exception) {
        return 0;
    }
}

- (NSString *)getMimeTypeAsyncWithAssetId:(NSString *)assetId {
    PHFetchResult *fetchResult = [self fetchAssetsWithLocalIdentifiersSafely:@[assetId]
                                                                     options:[self singleFetchOptions]
                                                                   operation:@"getMimeTypeAsyncWithAssetId"];
    PHAsset *asset = [self getFirstObjFromFetchResult:fetchResult];
    if (asset) {
        return [asset mimeType];
    }
    return nil;
}

- (void)getMediaUrl:(NSString *)assetId
      resultHandler:(PMResultHandler *)handler
    progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PHFetchResult<PHAsset *> *fetchResult = [self fetchAssetsWithLocalIdentifiersSafely:@[assetId]
                                                                                 options:[self singleFetchOptions]
                                                                               operation:@"getMediaUrl"];
    PHAsset *asset = fetchResult.firstObject;
    if (!asset) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ is not found", assetId]];
        [self notifyProgress:progressHandler progress:0 state:PMProgressStateFailed];
        return;
    }
    
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

- (NSArray<PMAssetPathEntity *> *)getParentPathWithId:(NSString *)id type:(int)type albumType:(int)albumType option:(NSObject<PMBaseFilter> *)option {
    PHFetchOptions *options = [self getAssetOptions:type filterOption:option];

    // The root and system albums (e.g. Recent, All Photos) have no parent.
    if ([PMFolderUtils isRecentCollection:id]) {
        return @[];
    }

    // Both albums (PHAssetCollection) and folders (PHCollectionList) can be
    // contained by a parent folder, so resolve the input accordingly.
    PHCollection *collection;
    if (albumType == PM_TYPE_ALBUM) {
        PHFetchResult<PHAssetCollection *> *result =
            [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id] options:nil];
        collection = result.firstObject;
    } else {
        PHFetchResult<PHCollectionList *> *result =
            [PHCollectionList fetchCollectionListsWithLocalIdentifiers:@[id] options:nil];
        collection = result.firstObject;
    }
    if (!collection) {
        return @[];
    }

    PHFetchResult<PHCollectionList *> *parents =
        [PHCollectionList fetchCollectionListsContainingCollection:collection options:nil];
    NSMutableArray<PHCollection *> *parentArray = [NSMutableArray new];
    for (PHCollectionList *parent in parents) {
        [parentArray addObject:parent];
    }
    return [self convertPHCollectionToPMAssetPathArray:parentArray option:options];
}

- (NSDictionary<NSString *, id> *)getCloudIdentifiersWithIds:(NSArray<NSString *> *)ids {
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionary];
    if (@available(iOS 15.0, macOS 12.0, *)) {
        NSDictionary<NSString *, PHCloudIdentifierMapping *> *mappings =
            [PHPhotoLibrary.sharedPhotoLibrary cloudIdentifierMappingsForLocalIdentifiers:ids];
        for (NSString *localId in ids) {
            PHCloudIdentifierMapping *mapping = mappings[localId];
            NSString *value = nil;
            if (mapping && mapping.error == nil) {
                value = mapping.cloudIdentifier.stringValue;
            }
            // Keep the key so callers can tell "resolved to nothing" from
            // "not requested"; NSNull is decoded as null on the Dart side.
            result[localId] = value ?: (id) [NSNull null];
        }
    }
    return result;
}

- (BOOL)hasAdjustmentsWithId:(NSString *)assetId {
    PMAssetEntity *entity = [self getAssetEntity:assetId];
    if (!entity || !entity.phAsset) {
        return NO;
    }
    // Detect the adjustment-data resource. This is reliable across OS versions,
    // unlike `PHAsset.hasAdjustments` which is only exposed on newer systems.
    NSArray<PHAssetResource *> *resources =
        [PHAssetResource assetResourcesForAsset:entity.phAsset];
    for (PHAssetResource *resource in resources) {
        if (resource.type == PHAssetResourceTypeAdjustmentData) {
            return YES;
        }
    }
    return NO;
}

- (void)getBaseAdjustmentFileWithId:(NSString *)assetId
                           isOrigin:(BOOL)isOrigin
                           fileType:(AVFileType)fileType
                      resultHandler:(PMResultHandler *)handler
                    progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PMAssetEntity *entity = [self getAssetEntity:assetId];
    if (!entity || !entity.phAsset) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ file cannot be obtained.", assetId]];
        return;
    }
    PHAsset *asset = entity.phAsset;
    PHAssetResource *resource = [asset getOriginalResource];
    if (!resource) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ does not have a base resource.", assetId]];
        return;
    }
    // `fetchVideoResourceToFile:` writes an arbitrary resource's bytes to disk
    // (and only performs AV conversion when a fileType is supplied), so it works
    // for images too.
    [self notifyProgress:progressHandler progress:0 state:PMProgressStatePrepare];
    [self fetchVideoResourceToFile:asset
                          resource:resource
                   progressHandler:progressHandler
                        withScheme:NO
                          isOrigin:isOrigin
                          fileType:fileType
                             block:^(NSString *path, NSObject *error) {
        if (path) {
            [handler reply:path];
        } else {
            [handler replyError:error];
        }
    }];
}

- (void)getAdjustmentDataWithId:(NSString *)assetId
                  resultHandler:(PMResultHandler *)handler
                progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    PMAssetEntity *entity = [self getAssetEntity:assetId];
    if (!entity || !entity.phAsset) {
        [handler replyError:[NSString stringWithFormat:@"Asset %@ file cannot be obtained.", assetId]];
        return;
    }
    PHAssetResource *resource = [entity.phAsset getAdjustmentDataResource];
    if (!resource) {
        // The asset has no adjustment data; reply with null so the Dart side
        // resolves to `null` rather than an error.
        [self notifySuccess:progressHandler];
        [handler reply:nil];
        return;
    }

    PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
    [options setNetworkAccessAllowed:YES];

    __block double lastProgress = 0.0;
    // `Prepare` is emitted once from the caller so multi-candidate walks don't
    // bounce progress observers back to 0 between attempts.
    __weak typeof(self) weakSelf = self;
    [options setProgressHandler:^(double progress) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        lastProgress = progress;
        if (progress != 1) {
            [strongSelf notifyProgress:progressHandler progress:progress state:PMProgressStateLoading];
        }
    }];

    // Adjustment data can be delivered across multiple callbacks, so accumulate.
    NSMutableData *buffer = [NSMutableData data];
    PHAssetResourceManager *resourceManager = PHAssetResourceManager.defaultManager;
    [resourceManager requestDataForAssetResource:resource
                                         options:options
                             dataReceivedHandler:^(NSData *_Nonnull data) {
        [buffer appendData:data];
    }
                               completionHandler:^(NSError *_Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            [strongSelf notifyProgress:progressHandler progress:lastProgress state:PMProgressStateFailed];
            [handler replyError:error.localizedDescription];
        } else {
            id result = [strongSelf.converter convertData:buffer];
            [handler reply:result];
            [strongSelf notifySuccess:progressHandler];
        }
    }];
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
    
    __block PHFetchResult<PHAsset *> *asset = [self fetchAssetsWithLocalIdentifiersSafely:@[id]
                                                                                   options:[self singleFetchOptions]
                                                                                 operation:@"copyAssetWithId"];
    if (!asset || asset.count == 0) {
        block(nil, [NSString stringWithFormat:@"Asset [%@] not found.", id]);
        return;
    }
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
    PHFetchResult<PHAsset *> *assetResult = [self fetchAssetsWithLocalIdentifiersSafely:ids
                                                                                options:options
                                                                              operation:@"removeInAlbumWithAssetId"];
    if (!assetResult) {
        block(@"Failed to fetch assets to remove from album.");
        return;
    }
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
    PHFetchResult *fetchResult = [self fetchAssetsWithLocalIdentifiersSafely:@[id]
                                                                     options:[self singleFetchOptions]
                                                                   operation:@"favoriteWithId"];
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

- (void)updateCreationDateWithId:(NSString *)id timestamp:(NSNumber *)timestamp block:(void (^)(BOOL result, NSObject *error))block {
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
    
    NSTimeInterval timeInterval = [timestamp doubleValue];
    NSDate *newDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    
    NSError *error;
    BOOL succeed = [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:asset];
        request.creationDate = newDate;
    } error:&error];
    if (!succeed) {
        block(NO, [NSString stringWithFormat:@"Updating creation date for asset %@ failed: Request not succeed.", id]);
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
    PHFetchResult<PHAsset *> *fetchResult = [self fetchAssetsWithLocalIdentifiersSafely:ids
                                                                                options:fetchOptions
                                                                              operation:@"requestCacheAssetsThumb"];
    if (!fetchResult) {
        return;
    }
    NSMutableArray *array = [NSMutableArray new];
    
    for (id asset in fetchResult) {
        [array addObject:asset];
    }
    
    PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
    requestOptions.resizeMode = option.resizeMode;
    requestOptions.deliveryMode = option.deliveryMode;
    
    // PHImageManager methods must be called on the main thread to avoid crashes
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cachingManager startCachingImagesForAssets:array
                                              targetSize:[option makeSize]
                                             contentMode:option.contentMode
                                                 options:requestOptions];
    });
}

- (void)cancelCacheRequests {
    // PHImageManager methods must be called on the main thread to avoid crashes
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cachingManager stopCachingImagesForAllAssets];
    });
}

# pragma mark handle cancel request

- (void)handleCancelRequest:(PMResultHandler *)handler
            progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    [self notifyProgress:progressHandler progress:0 state:PMProgressStateCancel];
    [handler replyError:@"Request canceled"];
}

- (void)handleCancelRequestIfNeeded:(PMResultHandler *)handler
                     progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler {
    if ([handler isReplied]) {
        return;
    }
    [self handleCancelRequest:handler progressHandler:progressHandler];
}

- (void) addRequstId:(NSString *)cancelToken
            requestId:(PHImageRequestID)requestId {
    dispatch_sync(_requestIdQueue, ^{
        requestIdMap[cancelToken] = @(requestId);
    });
}

// When the request is finished
- (void) removeRequstIdWithCancelToken:(NSString *)cancelToken {
    dispatch_sync(_requestIdQueue, ^{
        [requestIdMap removeObjectForKey:cancelToken];
    });
}

- (BOOL) isRequestActiveWithCancelToken:(NSString *)cancelToken {
    __block BOOL active = NO;
    dispatch_sync(_requestIdQueue, ^{
        active = requestIdMap[cancelToken] != nil;
    });
    return active;
}

- (BOOL) consumeRequestWithCancelToken:(NSString *)cancelToken {
    __block BOOL active = NO;
    dispatch_sync(_requestIdQueue, ^{
        active = requestIdMap[cancelToken] != nil;
        if (active) {
            [requestIdMap removeObjectForKey:cancelToken];
        }
    });
    return active;
}

- (void) cancelRequestWithCancelToken:(NSString *)cancelToken {
    __block NSNumber *requestId = nil;
    dispatch_sync(_requestIdQueue, ^{
        requestId = requestIdMap[cancelToken];
        if (requestId) {
            [requestIdMap removeObjectForKey:cancelToken];
        }
    });
    if (requestId) {
        // PHImageManager methods must be called on the main thread to avoid crashes
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cachingManager cancelImageRequest:requestId.intValue];
        });
    }
}

- (void) cancelAllRequest {
    __block NSArray<NSNumber *> *requestIds = nil;
    dispatch_sync(_requestIdQueue, ^{
        requestIds = [requestIdMap allValues];
        [requestIdMap removeAllObjects];
    });
    // PHImageManager methods must be called on the main thread to avoid crashes
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSNumber *requestId in requestIds) {
            [self.cachingManager cancelImageRequest:requestId.intValue];
        }
    });
}

# pragma mark progress
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
