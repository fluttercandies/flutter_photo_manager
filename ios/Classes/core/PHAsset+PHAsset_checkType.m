//
//  PHAsset+PHAsset_checkType.m
//  photo_manager
//
//  Created by Caijinglong on 2018/10/11.
//

#import "PHAsset+PHAsset_checkType.h"

@implementation PHAsset (PHAsset_checkType)

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
        return [self mediaSubtypes] == PHAssetMediaSubtypePhotoLive;
    }
    return NO;
}

- (int)unwrappedSubtype {
    PHAssetMediaSubtype subtype = [self mediaSubtypes];
    if (subtype & PHAssetMediaSubtypePhotoPanorama) {
        return 1;
    }
    if (subtype & PHAssetMediaSubtypePhotoHDR) {
        return 2;
    }
    if (subtype & PHAssetMediaSubtypePhotoScreenshot) {
        return 4;
    }
    if (@available(iOS 9.1, *)) {
        if (subtype & PHAssetMediaSubtypePhotoLive) {
            return 8;
        }
    }
    if (@available(iOS 10.2, *)) {
        if (subtype & PHAssetMediaSubtypePhotoDepthEffect) {
            return 16;
        }
    }
    if (subtype & PHAssetMediaSubtypeVideoStreamed) {
        return 65536;
    }
    if (subtype & PHAssetMediaSubtypeVideoHighFrameRate) {
        return 131072;
    }
    if (subtype & PHAssetMediaSubtypeVideoTimelapse) {
        return 262144;
    }
    return 0;
}

@end
