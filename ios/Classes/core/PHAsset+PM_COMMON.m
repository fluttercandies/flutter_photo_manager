//
//  PHAsset+PHAsset_checkType.m
//  photo_manager
//

#import "PHAsset+PM_COMMON.h"
#import "PHAssetResource+PM_COMMON.h"
#import "PMConvertUtils.h"
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

@implementation PHAsset (PM_COMMON)

- (bool)isImage{
    return [self mediaType] == PHAssetMediaTypeImage;
}

- (bool)isVideo{
    return [self mediaType] == PHAssetMediaTypeVideo;
}

- (bool)isAudio{
    return [self mediaType] == PHAssetMediaTypeAudio;
}

- (bool)isImageOrVideo{
    return [self isVideo] || [self isImage];
}

- (bool)isLivePhoto {
    if (@available(iOS 9.1, *)) {
        return (self.mediaSubtypes & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive;
    }
    if (@available(macOS 14.0, *)) {
        return (self.mediaSubtypes & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive;
    }
    return NO;
}

- (NSString *)title {
    PMLogUtils *logger = [PMLogUtils sharedInstance];
    [logger info:@"get title start"];
    @try {
        NSString *result = [self valueForKey:@"filename"];
        [logger info:@"get title from kvo"];
        return result;
    } @catch (NSException *exception) {
        [logger info: @"get title from PHAssetResource"];
        NSArray *array = [PHAssetResource assetResourcesForAsset:self];
        for (PHAssetResource *resource in array) {
            if ([self isImage] && resource.type == PHAssetResourceTypePhoto) {
                return resource.originalFilename;
            } else if ([self isVideo] && resource.type == PHAssetResourceTypeVideo) {
                return resource.originalFilename;
            }
        }
        
        PHAssetResource *firstRes = array.firstObject;
        if (firstRes) {
            return firstRes.originalFilename;
        }
        
        return @"";
    }
}

- (NSString *)filenameWithOptions:(int)subtype isOrigin:(BOOL)isOrigin fileType:(AVFileType)fileType {
    PHAssetResource *resource;
    if (@available(iOS 9.1, *)) {
        BOOL isLivePhotoSubtype = (subtype & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive;
        if ([self isLivePhoto] && isLivePhotoSubtype) {
            resource = [self getLivePhotosResource];
        } else if (isOrigin) {
            resource = [self getRawResource];
        } else {
            resource = [self getCurrentResource];
        }
    } else if (isOrigin) {
        resource = [self getRawResource];
    } else {
        resource = [self getCurrentResource];
    }
    if (resource) {
        NSString *filename = resource.originalFilename;
        if (fileType) {
            NSString *extension = [PMConvertUtils convertAVFileTypeToExtension:fileType];
            filename = [filename stringByDeletingPathExtension];
            filename = [filename stringByAppendingPathExtension:[extension stringByReplacingOccurrencesOfString:@"." withString:@""]];
        }
        return filename;
    }
    return @"";
}

// UTI: https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_intro/understand_utis_intro.html#//apple_ref/doc/uid/TP40001319
- (NSString *)mimeType {
    PHAssetResource *resource = [[PHAssetResource assetResourcesForAsset:self] firstObject];
    if (resource) {
        NSString *uti = resource.uniformTypeIdentifier;
        return (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)uti, kUTTagClassMIMEType);
    }
    return nil;
}

- (BOOL)isAdjust {
    NSArray<PHAssetResource *> *resources =
    [PHAssetResource assetResourcesForAsset:self];
    if (resources.count == 1) {
        return NO;
    }
    
    if (self.mediaType == PHAssetMediaTypeImage) {
        return [self imageIsAdjust:resources];
    }
    if (self.mediaType == PHAssetMediaTypeVideo) {
        return [self videoIsAdjust:resources];
    }
    
    return NO;
}

- (BOOL)imageIsAdjust:(NSArray<PHAssetResource *> *)resources {
    if (self.mediaSubtypes != PHAssetMediaSubtypeNone) {
        return NO;
    }
    for (PHAssetResource *res in resources) {
        if (res.type == PHAssetResourceTypeFullSizePhoto) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)videoIsAdjust:(NSArray<PHAssetResource *> *)resources {
    for (PHAssetResource *res in resources) {
        if (res.type == PHAssetResourceTypeFullSizeVideo) {
            return YES;
        }
    }
    return NO;
}

- (PHAssetResource *)getRawResource {
    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:self];
    for (PHAssetResource *res in resources) {
        if (self.isImage && res.isImage && res.type == PHAssetResourceTypePhoto) {
            return res;
        }
        if (self.isVideo && res.isVideo && res.type == PHAssetResourceTypeVideo) {
            return res;
        }
        if (self.isAudio && res.isAudio && res.type == PHAssetResourceTypeAudio) {
            return res;
        }
    }
    return nil;
}

- (PHAssetResource *)getCurrentResource {
    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:self];
    NSMutableArray<PHAssetResource *> *filtered = [NSMutableArray array];
    for (PHAssetResource *res in resources) {
        if (!res.isValid) {
            continue;
        }
        BOOL isAllowedType = NO;
        if (self.isImage && res.isImage) {
            isAllowedType = res.type == PHAssetResourceTypePhoto ||
            res.type == PHAssetResourceTypeAlternatePhoto ||
            res.type == PHAssetResourceTypeFullSizePhoto;
        } else if (self.isVideo && res.isVideo) {
            isAllowedType = res.type == PHAssetResourceTypeVideo ||
            res.type == PHAssetResourceTypeFullSizeVideo ||
            res.type == PHAssetResourceTypeFullSizePairedVideo;
        } else if (self.isAudio && res.isAudio) {
            isAllowedType = res.type == PHAssetResourceTypeAudio;
        }
        if (isAllowedType) {
            [filtered addObject:res];
        }
    }
    if (filtered.count == 0) {
        return nil;
    }
    
    if (filtered.count == 1) {
        return resources[0];
    }
    
    for (PHAssetResource *res in filtered) {
        BOOL isCurrent = [[res valueForKey:@"isCurrent"] boolValue];
        if (isCurrent) {
            return res;
        }
    }
    for (PHAssetResource *res in filtered) {
        if (self.mediaType == PHAssetMediaTypeImage &&
            res.type == PHAssetResourceTypeFullSizePhoto) {
            return res;
        }
        if (self.mediaType == PHAssetMediaTypeVideo &&
            res.type == PHAssetResourceTypeFullSizeVideo) {
            return res;
        }
    }
    return nil;
}

- (void)requestCurrentResourceData:(void (^)(NSData *_Nullable))block {
    PHAssetResource *res = [self getCurrentResource];
    
    PHAssetResourceManager *manager = PHAssetResourceManager.defaultManager;
    PHAssetResourceRequestOptions *opt = [PHAssetResourceRequestOptions new];
    
    __block double pro = 0;
    
    opt.networkAccessAllowed = YES;
    opt.progressHandler = ^(double progress) {
        pro = progress;
    };
    
    [manager requestDataForAssetResource:res
                                 options:opt
                     dataReceivedHandler:^(NSData *_Nonnull data) {
        if (pro != 1) {
            return;
        }
        block(data);
    }
                       completionHandler:^(NSError *_Nullable error){
        
    }];
}

- (PHAssetResource *)getLivePhotosResource {
    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:self];
    if (resources.count == 0) {
        return nil;
    }
    if (@available(iOS 9.1, *)) {
        PHAssetResource *paired;
        PHAssetResource *fullSizePaired;
        for (PHAssetResource *r in resources) {
            if (r.type == PHAssetResourceTypePairedVideo && !paired) {
                paired = r;
                continue;
            }
            if (r.type == PHAssetResourceTypeFullSizePairedVideo && !fullSizePaired) {
                fullSizePaired = r;
                continue;
            }
        }
        return fullSizePaired ?: paired;
    }
    return nil;
}

@end
