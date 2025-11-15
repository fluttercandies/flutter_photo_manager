#import "PHAsset+PM_COMMON.h"
#import "PMAssetPathEntity.h"
#import "PMItemProviderHelper.h"
#import "PMItemProviderAsset.h"
#import "PMConvertUtils.h"
#import <PhotosUI/PhotosUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UTCoreTypes.h>

NSString * const UTI_LIVE_PHOTO_BUNDLE = @"com.apple.live-photo-bundle";

@implementation PMItemProviderHelper

- (void)handleItemProvider:(NSItemProvider *)itemProvider
                    result:(PHPickerResult *)result
                   manager:(PMManager *)manager
                  entities:(NSMutableArray<NSDictionary *> *)entities
        itemProviderAssets:(NSMutableArray<PMItemProviderAsset *> *)itemProviderAssets
                     group:(dispatch_group_t)group API_AVAILABLE(ios(14)) {
    
    NSString *assetId = result.assetIdentifier;
    if (!assetId) {
        assetId = [NSString stringWithFormat:@"%f-%f", [[NSDate date] timeIntervalSince1970], drand48()];
    }
    
    if ([itemProvider hasItemConformingToTypeIdentifier:UTI_LIVE_PHOTO_BUNDLE]) {
        [self handleLivePhoto:itemProvider assetId:assetId itemProviderAssets:itemProviderAssets entities:entities group:group];
    } else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeImage.identifier]) {
        [self handleImage:itemProvider assetId:assetId itemProviderAssets:itemProviderAssets entities:entities group:group];
    } else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeVideo.identifier]) {
        [self handleVideo:itemProvider assetId:assetId itemProviderAssets:itemProviderAssets entities:entities group:group];
    } else if (result.assetIdentifier) {
        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[result.assetIdentifier] options:nil];
        if (assets.firstObject) {
            PHAsset *asset = assets.firstObject;
            NSDate *date = asset.creationDate;
            long createDt = (long) date.timeIntervalSince1970;
            NSDate *modifiedDate = asset.modificationDate;
            long modifiedTimeStamp = (long) modifiedDate.timeIntervalSince1970;
            int type = 0;
            if (asset.isImage) {
                type = 1;
            } else if (asset.isVideo) {
                type = 2;
            }
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
            entity.favorite = asset.isFavorite;
            entity.subtype = asset.mediaSubtypes;
            [entities addObject:[PMConvertUtils convertPMAssetToMap:entity needTitle:NO]];
        }
        dispatch_group_leave(group);
    }
}

- (void)handleLivePhoto:(NSItemProvider *)itemProvider
                assetId:(NSString *)assetId
     itemProviderAssets:(NSMutableArray<PMItemProviderAsset *> *)itemProviderAssets
               entities:(NSMutableArray<NSDictionary *> *)entities
                  group:(dispatch_group_t)group API_AVAILABLE(ios(14)) {
    [itemProvider loadFileRepresentationForTypeIdentifier:UTI_LIVE_PHOTO_BUNDLE
                                        completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (url) {
            // Check if the path is a directory
            BOOL isDirectory = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory] && isDirectory) {
                // Find video and image files in the directory
                NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
                
                NSString *imagePath;
                NSString *videoPath;
                
                for (NSURL *fileURL in enumerator) {
                    NSString *filename = fileURL.lastPathComponent;
                    if ([filename.pathExtension.lowercaseString isEqualToString:@"mov"]) {
                        videoPath = [self copyToCache:fileURL assetId:assetId type:@"video"];
                    } else if ([filename.pathExtension.lowercaseString isEqualToString:@"heic"] || [filename.pathExtension.lowercaseString isEqualToString:@"jpg"]) {
                        imagePath = [self copyToCache:fileURL assetId:assetId type:@"image"];
                    }
                }
                
                if (imagePath && videoPath) {
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    AVURLAsset *avAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
                    CMTime duration = avAsset.duration;
                    
                    PMItemProviderAsset *asset = [PMItemProviderAsset assetWithId:assetId createDt:[[NSDate date] timeIntervalSince1970] width:image.size.width height:image.size.height duration:CMTimeGetSeconds(duration) type:1 subtype:PHAssetMediaSubtypePhotoLive path:imagePath];
                    [itemProviderAssets addObject:asset];
                    
                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
                        @"id": assetId,
                        @"width": @((int)image.size.width),
                        @"height": @((int)image.size.height),
                        @"duration": @(CMTimeGetSeconds(duration)),
//                        @"pickedFileUrl": videoPath,
                        @"type": @(1),
                        @"subtype": @(PHAssetMediaSubtypePhotoLive),
                        @"isLocal": @(YES),
                    }];
                    dict[@"title"] = itemProvider.suggestedName;
                    
                    [entities addObject:dict];
                }
            }
        }
        dispatch_group_leave(group);
    }];
}

- (void)handleImage:(NSItemProvider *)itemProvider
            assetId:(NSString *)assetId
 itemProviderAssets:(NSMutableArray<PMItemProviderAsset *> *)itemProviderAssets
           entities:(NSMutableArray<NSDictionary *> *)entities
              group:(dispatch_group_t)group API_AVAILABLE(ios(14)) {
    [itemProvider loadFileRepresentationForTypeIdentifier:UTTypeImage.identifier
                                        completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (url) {
            NSString *tmpPath = [self copyToCache:url assetId:assetId type:@"image"];
            if (tmpPath) {
                UIImage *image = [UIImage imageWithContentsOfFile:tmpPath];
                PMItemProviderAsset *asset = [PMItemProviderAsset assetWithId:assetId createDt:[[NSDate date] timeIntervalSince1970] width:image.size.width height:image.size.height duration:0 type:1 subtype:0 path:tmpPath];
                [itemProviderAssets addObject:asset];
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
                    @"id": assetId,
                    @"width": @((int)image.size.width),
                    @"height": @((int)image.size.height),
                    @"type": @(1),
                    @"isLocal": @(YES),
                }];
                dict[@"title"] = itemProvider.suggestedName;
                
                NSData *data = [NSData dataWithContentsOfFile:tmpPath];
                CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
                if (imageSource) {
                    NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache: @NO};
                    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
                    if (imageProperties) {
                        NSDictionary *gpsDict = [(__bridge NSDictionary *)imageProperties objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
                        if (gpsDict) {
                            NSNumber *latitude = gpsDict[(NSString *)kCGImagePropertyGPSLatitude];
                            NSNumber *longitude = gpsDict[(NSString *)kCGImagePropertyGPSLongitude];
                            NSString *latitudeRef = gpsDict[(NSString *)kCGImagePropertyGPSLatitudeRef];
                            NSString *longitudeRef = gpsDict[(NSString *)kCGImagePropertyGPSLongitudeRef];
                            
                            if (latitude && longitude && latitudeRef && longitudeRef) {
                                double lat = [latitude doubleValue];
                                double lng = [longitude doubleValue];
                                if ([latitudeRef isEqualToString:@"S"]) {
                                    lat = -lat;
                                }
                                if ([longitudeRef isEqualToString:@"W"]) {
                                    lng = -lng;
                                }
                                dict[@"lat"] = @(lat);
                                dict[@"lng"] = @(lng);
                            }
                        }
                        CFRelease(imageProperties);
                    }
                    CFRelease(imageSource);
                }
                
                [entities addObject:dict];
            }
        }
        dispatch_group_leave(group);
    }];
}

- (void)handleVideo:(NSItemProvider *)itemProvider
            assetId:(NSString *)assetId
 itemProviderAssets:(NSMutableArray<PMItemProviderAsset *> *)itemProviderAssets
           entities:(NSMutableArray<NSDictionary *> *)entities
              group:(dispatch_group_t)group API_AVAILABLE(ios(14)) {
    [itemProvider loadFileRepresentationForTypeIdentifier:UTTypeVideo.identifier
                                        completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (url) {
            NSString *tmpPath = [self copyToCache:url assetId:assetId type:@"video"];
            if (tmpPath) {
                AVURLAsset *avAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:tmpPath]];
                CMTime duration = avAsset.duration;
                PMItemProviderAsset *asset = [PMItemProviderAsset assetWithId:assetId createDt:[[NSDate date] timeIntervalSince1970] width:avAsset.naturalSize.width height:avAsset.naturalSize.height duration:CMTimeGetSeconds(duration) type:2 subtype:0 path:tmpPath];
                [itemProviderAssets addObject:asset];
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
                    @"id": assetId,
                    @"pickedFileUrl": tmpPath,
                    @"width": @((int)avAsset.naturalSize.width),
                    @"height": @((int)avAsset.naturalSize.height),
                    @"duration": @(CMTimeGetSeconds(duration)),
                    @"type": @(2),
                    @"isLocal": @(YES),
                }];
                
                dict[@"title"] = itemProvider.suggestedName;
                [entities addObject:dict];
            }
        }
        dispatch_group_leave(group);
    }];
}

- (NSString *)copyToCache:(NSURL *)url assetId:(NSString *)assetId type:(NSString *)type {
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%@-%@.%@", assetId, type, url.pathExtension];
    NSString *tmpPath = [tmpDir stringByAppendingPathComponent:fileName];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:tmpPath]) {
        [fm removeItemAtPath:tmpPath error:nil];
    }
    
    if ([fm copyItemAtURL:url toURL:[NSURL fileURLWithPath:tmpPath] error:nil]) {
        return tmpPath;
    }
    return nil;
}

@end
