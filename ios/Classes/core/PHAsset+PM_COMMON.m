//
//  PHAsset+PHAsset_checkType.m
//  photo_manager
//

#import "PHAsset+PM_COMMON.h"
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

- (NSString *)originalFilenameWithSubtype:(int)subtype {
    if (@available(iOS 9.1, *)) {
        if ([self isLivePhoto] && subtype == PHAssetMediaSubtypePhotoLive) {
            return [self getLivePhotosResource].originalFilename;
        }
    }
    PHAssetResource *resource = [self getUntouchedResource];
    if (resource) {
        return resource.originalFilename;
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

- (PHAssetResource *)getUntouchedResource {
    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:self];
    if (resources.count == 0) {
        return nil;
    }

    if (resources.count == 1) {
        return resources[0];
    }

    for (PHAssetResource *res in resources) {
        if (self.mediaType == PHAssetMediaTypeImage
            && res.type == PHAssetResourceTypePhoto) {
            return res;
        }
        
        if (self.mediaType == PHAssetMediaTypeVideo
            && res.type == PHAssetResourceTypeVideo) {
            return res;
        }
    }
    
    return nil;
}

- (PHAssetResource *)getAdjustResource {
    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:self];
    if (resources.count == 0) {
        return nil;
    }
    
    if (resources.count == 1) {
        return resources[0];
    }
    
    if (![self isAdjust]) {
        for (PHAssetResource *res in resources) {
            if (self.mediaType == PHAssetMediaTypeImage
                && res.type == PHAssetResourceTypePhoto) {
                return res;
            }
            
            if (self.mediaType == PHAssetMediaTypeVideo
                && res.type == PHAssetResourceTypeVideo) {
                return res;
            }
        }
        
        return nil;
    }
    
    for (PHAssetResource *res in resources) {
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

- (void)requestAdjustedData:(void (^)(NSData *_Nullable))block {
    PHAssetResource *res = [self getAdjustResource];
    
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
    NSArray<PHAssetResource *> *resources =
    [PHAssetResource assetResourcesForAsset:self];
    if (resources.count == 0) {
        return nil;
    }
    
    if (resources.count == 1) {
        return resources[0];
    }
    PHAssetResource *resource;
    
    if (@available(iOS 9.1, *)) {
        if (resources.lastObject && resources.lastObject.type == PHAssetResourceTypePairedVideo) {
            resource = resources.lastObject;
        }
        if (!resource) {
            for (PHAssetResource *r in resources) {
                // Iterate to find the paired video.
                if (r.type == PHAssetResourceTypePairedVideo) {
                    resource = r;
                    break;
                }
            }
        }
    }
    return resource;
}

@end
