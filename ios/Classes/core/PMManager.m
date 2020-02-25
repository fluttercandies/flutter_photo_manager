//
// Created by Caijinglong on 2019-09-06.
//

#import "PMManager.h"
#import "PHAsset+PHAsset_checkType.h"
#import "PHAsset+PHAsset_getTitle.h"
#import "PMAssetPathEntity.h"
#import "PMCacheContainer.h"
#import "PMFilterOption.h"
#import "PMLogUtils.h"
#import "ResultHandler.h"

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

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type
                                            date:(NSDate *)date
                                          hasAll:(BOOL)hasAll
                                          option:(PMFilterOptionGroup *)option {
  NSMutableArray<PMAssetPathEntity *> *array = [NSMutableArray new];

  PHFetchOptions *assetOptions = [self getAssetOptions:type
                                                  date:date
                                          filterOption:option];

  PHFetchOptions *fetchCollectionOptions = [PHFetchOptions new];

  PHFetchResult<PHAssetCollection *> *smartAlbumResult = [PHAssetCollection
          fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                subtype:PHAssetCollectionSubtypeAlbumRegular
                                options:fetchCollectionOptions];
  [self injectAssetPathIntoArray:array
                          result:smartAlbumResult
                         options:assetOptions
                          hasAll:hasAll];

  PHFetchResult<PHCollection *> *topLevelResult = [PHAssetCollection
          fetchTopLevelUserCollectionsWithOptions:fetchCollectionOptions];
  [self injectAssetPathIntoArray:array
                          result:topLevelResult
                         options:assetOptions
                          hasAll:hasAll];

  return array;
}

- (BOOL)existsWithId:(NSString *)assetId {
  PHFetchResult<PHAsset *> *result =
          [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId]
                                           options:[PHFetchOptions new]];
  if (!result) {
    return NO;
  }
  return result.count >= 1;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCDFAInspection"

- (void)injectAssetPathIntoArray:(NSMutableArray<PMAssetPathEntity *> *)array
                          result:(PHFetchResult *)result
                         options:(PHFetchOptions *)options
                          hasAll:(BOOL)hasAll {
  for (id collection in result) {
    if (![collection isMemberOfClass:[PHAssetCollection class]]) {
      continue;
    }

    PHAssetCollection *assetCollection = (PHAssetCollection *) collection;

    PHFetchResult<PHAsset *> *fetchResult =
            [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];

    PMAssetPathEntity *entity =
            [PMAssetPathEntity entityWithId:assetCollection.localIdentifier
                                       name:assetCollection.localizedTitle
                                 assetCount:(int) fetchResult.count];

    entity.isAll = assetCollection.assetCollectionSubtype ==
            PHAssetCollectionSubtypeSmartAlbumUserLibrary;

    if (!hasAll && entity.isAll) {
      continue;
    }

    if (entity.assetCount && entity.assetCount > 0) {
      [array addObject:entity];
    }
  }
}

#pragma clang diagnostic pop

- (NSArray<PMAssetEntity *> *)
getAssetEntityListWithGalleryId:(NSString *)id
                           type:(int)type
                           page:(NSUInteger)page
                      pageCount:(NSUInteger)pageCount
                           date:(NSDate *)date
                   filterOption:(PMFilterOptionGroup *)filterOption {
  NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

  PHFetchOptions *options = [PHFetchOptions new];

  PHFetchResult<PHAssetCollection *> *fetchResult =
          [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                                               options:options];
  if (fetchResult && fetchResult.count == 0) {
    return result;
  }

  PHFetchOptions *assetOptions = [self getAssetOptions:type
                                                  date:date
                                          filterOption:filterOption];

  PHAssetCollection *collection = fetchResult.firstObject;

  PHFetchResult<PHAsset *> *assetArray =
          [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

  if (assetArray.count == 0) {
    return result;
  }

  NSUInteger startIndex = page * pageCount;
  NSUInteger endIndex = startIndex + pageCount - 1;

  NSUInteger count = assetArray.count;
  if (endIndex >= count) {
    endIndex = count - 1;
  }

  BOOL imageNeedTitle = filterOption.imageOption.needTitle;
  BOOL videoNeedTitle = filterOption.videoOption.needTitle;

  for (NSUInteger i = startIndex; i <= endIndex; i++) {
    PHAsset *asset = assetArray[i];
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

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithRange:(NSString *)id
                                                     type:(NSUInteger)type
                                                    start:(NSUInteger)start
                                                      end:(NSUInteger)end
                                                     date:(NSDate *)date
                                             filterOption:(PMFilterOptionGroup *)
                                                     filterOption {
  NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

  PHFetchOptions *options = [PHFetchOptions new];

  PHFetchResult<PHAssetCollection *> *fetchResult =
          [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                                               options:options];
  if (fetchResult && fetchResult.count == 0) {
    return result;
  }

  PHFetchOptions *assetOptions = [self getAssetOptions:(int) type
                                                  date:date
                                          filterOption:filterOption];

  PHAssetCollection *collection = fetchResult.firstObject;
  PHFetchResult<PHAsset *> *assetArray =
          [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

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
    BOOL needTitle;

    PHAsset *asset = assetArray[i];

    if ([asset isVideo]) {
      needTitle = filterOption.videoOption.needTitle;
    } else if ([asset isImage]) {
      needTitle = filterOption.imageOption.needTitle;
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

  return entity;
}

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId
                        needTitle:(BOOL)needTitle {
  PMAssetEntity *entity = [cacheContainer getAssetEntity:assetId];
  if (entity) {
    return entity;
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

- (void)getThumbWithId:(NSString *)id
                 width:(NSUInteger)width
                height:(NSUInteger)height
                format:(NSUInteger)format
         resultHandler:(ResultHandler *)handler {
  PMAssetEntity *entity = [self getAssetEntity:id needTitle:NO];
  if (entity && entity.phAsset) {
    PHAsset *asset = entity.phAsset;
    [self fetchThumb:asset
               width:width
              height:height
              format:format
       resultHandler:handler];
  } else {
    [handler replyError:@"asset is not found"];
  }
}

- (void)fetchThumb:(PHAsset *)asset
             width:(NSUInteger)width
            height:(NSUInteger)height
            format:(NSUInteger)format
     resultHandler:(ResultHandler *)handler {
  PHImageManager *manager = PHImageManager.defaultManager;
  PHImageRequestOptions *options = [PHImageRequestOptions new];
  [options setNetworkAccessAllowed:YES];
  [options setProgressHandler:^(double progress, NSError *error, BOOL *stop,
          NSDictionary *info) {
      if (progress == 1.0) {
        [self fetchThumb:asset
                   width:width
                  height:height
                  format:format
           resultHandler:handler];
      }
  }];
  [manager requestImageForAsset:asset
                     targetSize:CGSizeMake(width, height)
                    contentMode:PHImageContentModeAspectFill
                        options:options
                  resultHandler:^(UIImage *result, NSDictionary *info) {
                      BOOL downloadFinished = [PMManager isDownloadFinish:info];

                      if (!downloadFinished) {
                        return;
                      }

                      if ([handler isReplied]) {
                        return;
                      }
                      NSData *imageData;
                      if (format == 1) {
                        imageData = UIImagePNGRepresentation(result);
                      } else {
                        imageData = UIImageJPEGRepresentation(result, 0.95);
                      }

                      FlutterStandardTypedData *data =
                              [FlutterStandardTypedData typedDataWithBytes:imageData];
                      [handler reply:data];
                  }];
}

- (void)getFullSizeFileWithId:(NSString *)id
                     isOrigin:(BOOL)isOrigin
                resultHandler:(ResultHandler *)handler {
  PMAssetEntity *entity = [self getAssetEntity:id needTitle:NO];
  if (entity && entity.phAsset) {
    PHAsset *asset = entity.phAsset;
    if (asset.isVideo) {
      if (isOrigin) {
        [self fetchOriginVideoFile:asset handler:handler];
      } else {
        [self fetchFullSizeVideo:asset handler:handler];
      }
      return;
    } else {
      if (isOrigin) {
        [self fetchOriginImageFile:asset resultHandler:handler];
      } else {
        [self fetchOriginImageFile:asset resultHandler:handler];
      }
    }
  } else {
    [handler replyError:@"asset is not found"];
  }
}

- (void)fetchOriginVideoFile:(PHAsset *)asset handler:(ResultHandler *)handler {
  NSArray<PHAssetResource *> *resources =
          [PHAssetResource assetResourcesForAsset:asset];
  // find asset
  NSLog(@"The asset has %lu resources.", (unsigned long) resources.count);
  PHAssetResource *dstResource;
  if (resources.lastObject && resources.lastObject.type == PHAssetResourceTypeVideo) {
    dstResource = resources.lastObject;
  } else {
    for (PHAssetResource *resource in resources) {
      if (resource.type == PHAssetResourceTypeVideo) {
        dstResource = resource;
        break;
      }
    }
  }
  if (!dstResource) {
    [handler reply:nil];
    return;
  }

  PHAssetResourceManager *manager = PHAssetResourceManager.defaultManager;

  NSString *path = [self makeAssetOutputPath:asset isOrigin:YES];
  NSURL *fileUrl = [NSURL fileURLWithPath:path];

  [PMFileHelper deleteFile:path];

  PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
  [options setNetworkAccessAllowed:YES];

  [manager writeDataForAssetResource:dstResource
                              toFile:fileUrl
                             options:options
                   completionHandler:^(NSError *_Nullable error) {
                       if (error) {
                         NSLog(@"error = %@", error);
                         [handler reply:nil];
                       } else {
                         [handler reply:path];
                       }
                   }];
}

- (void)fetchFullSizeVideo:(PHAsset *)asset handler:(ResultHandler *)handler {
  NSString *homePath = NSTemporaryDirectory();
  NSFileManager *manager = NSFileManager.defaultManager;

  NSMutableString *path = [NSMutableString stringWithString:homePath];

  NSString *filename = [asset valueForKey:@"filename"];

  NSString *dirPath = [NSString stringWithFormat:@"%@/%@", homePath, @".video"];
  [manager createDirectoryAtPath:dirPath
     withIntermediateDirectories:true
                      attributes:@{}
                           error:nil];

  [path appendFormat:@"%@/%@", @".video", filename];
  PHVideoRequestOptions *options = [PHVideoRequestOptions new];
  if ([manager fileExistsAtPath:path]) {
    [[PMLogUtils sharedInstance]
            info:[NSString stringWithFormat:@"read cache from %@", path]];
    [handler reply:path];
    return;
  }

  [options setProgressHandler:^(double progress, NSError *error, BOOL *stop,
          NSDictionary *info) {
      if (progress == 1.0) {
        [self fetchFullSizeVideo:asset handler:handler];
      }
  }];

  [options setNetworkAccessAllowed:YES];

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

                       NSString *preset = AVAssetExportPresetHighestQuality;
                       AVAssetExportSession *exportSession =
                               [AVAssetExportSession exportSessionWithAsset:asset
                                                                 presetName:preset];
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

- (NSString *)makeAssetOutputPath:(PHAsset *)asset isOrigin:(Boolean)isOrigin {
  NSString *homePath = NSTemporaryDirectory();
  NSString *cachePath = asset.isVideo ? @".video" : @".image";
  NSString *dirPath = [NSString stringWithFormat:@"%@%@", homePath, cachePath];
  [NSFileManager.defaultManager createDirectoryAtPath:dirPath
                          withIntermediateDirectories:true
                                           attributes:@{}
                                                error:nil];

  NSLog(@"cache path = %@", dirPath);

  NSString *title = [asset title];
  NSMutableString *path = [NSMutableString stringWithString:dirPath];
  NSString *filename =
          [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/"
                                                           withString:@"_"];
  if (isOrigin) {
    return [NSString stringWithFormat:@"%@/%@", dirPath, title];
  } else {
    [path appendFormat:@"%@/%@%@.jpg", cachePath, filename,
                       isOrigin ? @"_origin" : @""];
  }
  return path;
}

- (void)fetchFullSizeImageFile:(PHAsset *)asset
                 resultHandler:(ResultHandler *)handler {
  PHImageManager *manager = PHImageManager.defaultManager;
  PHImageRequestOptions *options = [PHImageRequestOptions new];

  [options setNetworkAccessAllowed:YES];
  [options setProgressHandler:^(double progress, NSError *error, BOOL *stop,
          NSDictionary *info) {
      if (progress == 1.0) {
        [self fetchFullSizeImageFile:asset resultHandler:handler];
      }
  }];

  [manager requestImageForAsset:asset
                     targetSize:PHImageManagerMaximumSize
                    contentMode:PHImageContentModeDefault
                        options:options
                  resultHandler:^(UIImage *_Nullable image,
                          NSDictionary *_Nullable info) {
                      BOOL downloadFinished = [PMManager isDownloadFinish:info];
                      if (!downloadFinished) {
                        return;
                      }

                      if ([handler isReplied]) {
                        return;
                      }

                      NSString *path = [self makeAssetOutputPath:asset
                                                        isOrigin:NO];

                      [UIImageJPEGRepresentation(image, 1.0) writeToFile:path
                                                              atomically:YES];

                      [handler reply:path];
                  }];
}

- (BOOL)isImage:(PHAssetResource *)resource {
  return resource.type == PHAssetResourceTypePhoto || resource.type == PHAssetResourceTypeFullSizePhoto;
}

- (void)fetchOriginImageFile:(PHAsset *)asset
               resultHandler:(ResultHandler *)handler {
  NSArray<PHAssetResource *> *resources =
          [PHAssetResource assetResourcesForAsset:asset];
  // find asset
  NSLog(@"The asset has %lu resources.", (unsigned long) resources.count);
  PHAssetResource *imageResource;

  if (resources.lastObject && [self isImage:resources.lastObject]) {
    imageResource = resources.lastObject;
  } else {
    for (PHAssetResource *resource in [resources reverseObjectEnumerator]) {
      if ([self isImage:resource]) {
        imageResource = resource;
        break;
      }
    }
  }

  if (!imageResource) {
    [handler reply:nil];
    return;
  }

  PHAssetResourceManager *manager = PHAssetResourceManager.defaultManager;

  NSString *path = [self makeAssetOutputPath:asset isOrigin:YES];
  NSURL *fileUrl = [NSURL fileURLWithPath:path];

  [PMFileHelper deleteFile:path];

  PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
  [options setNetworkAccessAllowed:YES];

  [manager writeDataForAssetResource:imageResource
                              toFile:fileUrl
                             options:options
                   completionHandler:^(NSError *_Nullable error) {
                       if (error) {
                         NSLog(@"error = %@", error);
                         [handler reply:nil];
                       } else {
                         [handler reply:path];
                       }
                   }];
}

+ (BOOL)isDownloadFinish:(NSDictionary *)info {
  return ![info[PHImageCancelledKey] boolValue] &&      // No cancel.
          !info[PHImageErrorKey] &&                      // Error.
          ![info[PHImageResultIsDegradedKey] boolValue]; // thumbnail
}

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id
                                      type:(int)type
                                      date:(NSDate *)date
                              filterOption:(PMFilterOptionGroup *)filterOption {
  PHFetchOptions *collectionFetchOptions = [PHFetchOptions new];
  PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection
          fetchAssetCollectionsWithLocalIdentifiers:@[id]
                                            options:collectionFetchOptions];

  if (result == nil || result.count == 0) {
    return nil;
  }
  PHAssetCollection *collection = result[0];
  PHFetchOptions *assetOptions = [self getAssetOptions:type
                                                  date:date
                                          filterOption:filterOption];
  PHFetchResult<PHAsset *> *fetchResult =
          [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];

  return [PMAssetPathEntity entityWithId:id
                                    name:collection.localizedTitle
                              assetCount:(int) fetchResult.count];
}

- (PHFetchOptions *)getAssetOptions:(int)type
                               date:(NSDate *)date
                       filterOption:(PMFilterOptionGroup *)optionGroup {
  PHFetchOptions *options = [PHFetchOptions new];
  options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];

  NSMutableString *cond = [NSMutableString new];
  NSMutableArray *args = [NSMutableArray new];

  if (type == 1) {
    PMFilterOption *imageOption = optionGroup.imageOption;

    NSString *sizeCond = [imageOption sizeCond];
    NSArray *sizeArgs = [imageOption sizeArgs];

    [cond appendString:@"mediaType == %d AND creationDate <= %@"];
    [args addObject:@(PHAssetMediaTypeImage)];
    [args addObject:date];

    [cond appendString:@" AND "];
    [cond appendString:sizeCond];
    [args addObjectsFromArray:sizeArgs];

  } else if (type == 2) {
    PMFilterOption *videoOption = optionGroup.videoOption;

    [cond appendString:@"mediaType == %d AND creationDate <= %@"];
    [args addObject:@(PHAssetMediaTypeVideo)];
    [args addObject:date];

    NSString *durationCond = [videoOption durationCond];
    NSArray *durationArgs = [videoOption durationArgs];
    [cond appendString:@" AND "];
    [cond appendString:durationCond];
    [args addObjectsFromArray:durationArgs];
  } else {
    [cond appendString:@"("]; //1

    PMFilterOption *imageOption = optionGroup.imageOption;
    NSString *sizeCond = [imageOption sizeCond];
    NSArray *sizeArgs = [imageOption sizeArgs];

    [cond appendString:@"(mediaType = %d AND "]; //2
    [cond appendString:sizeCond];
    [cond appendString:@" )"]; //2
    [args addObject:@(PHAssetMediaTypeImage)];
    [args addObjectsFromArray:sizeArgs];

    PMFilterOption *videoOption = optionGroup.videoOption;
    NSString *durationCond = [videoOption durationCond];
    NSArray *durationArgs = [videoOption durationArgs];

    [cond appendString:@"OR (mediaType == %d AND "]; //3
    [cond appendString:durationCond];
    [cond appendString:@" )"]; //3
    [args addObject:@(PHAssetMediaTypeVideo)];
    [args addObjectsFromArray:durationArgs];

    [cond appendString:@" )"]; //1
    [cond appendString:@" AND creationDate <= %@"];
    [args addObject:date];
  }

  options.predicate = [NSPredicate predicateWithFormat:cond argumentArray:args];

  return options;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

+ (void)openSetting {
  NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
  if ([[UIApplication sharedApplication] canOpenURL:url]) {
    [[UIApplication sharedApplication] openURL:url
                                       options:@{}
                             completionHandler:^(BOOL success) {

                             }];
  }
}

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
             NSLog(@"create asset : id = %@", assetId);
             block([self getAssetEntity:assetId needTitle:YES]);
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
  NSURL *fileURL = [NSURL fileURLWithPath:path];
  __block NSString *assetId = nil;
  [[PHPhotoLibrary sharedPhotoLibrary]
          performChanges:^{
              PHAssetCreationRequest *request = [PHAssetCreationRequest
                      creationRequestForAssetFromVideoAtFileURL:fileURL];
              PHAssetResourceCreationOptions *options =
                      [PHAssetResourceCreationOptions new];
              [options setOriginalFilename:title];
              [request addResourceWithType:PHAssetResourceTypeVideo
                                   fileURL:fileURL
                                   options:options];
              assetId = request.placeholderForCreatedAsset.localIdentifier;
          }
       completionHandler:^(BOOL success, NSError *error) {
           if (success) {
             NSLog(@"create asset : id = %@", assetId);
             block([self getAssetEntity:assetId needTitle:YES]);
           } else {
             NSLog(@"create fail");
             block(nil);
           }
       }];
}

- (NSString *)getTitleAsyncWithAssetId:(NSString *)assetId {
  PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
  if (asset) {
    return [asset title];
  }
  return @"";
}

@end
