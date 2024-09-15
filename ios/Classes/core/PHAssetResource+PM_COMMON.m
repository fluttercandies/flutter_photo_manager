//
//  PHAssetResource+PHAssetResource_checkType.m
//  photo_manager
//

#import "PHAssetResource+PM_COMMON.h"

@implementation PHAssetResource (PM_COMMON)

- (bool)isImage {
    return [self type] == PHAssetResourceTypePhoto
    || [self type] == PHAssetResourceTypeAlternatePhoto
    || [self type] == PHAssetResourceTypeFullSizePhoto
    || [self type] == PHAssetResourceTypeAdjustmentBasePhoto;
}

- (bool)isVideo {
    BOOL predicate = [self type] == PHAssetResourceTypeVideo || PHAssetResourceTypeFullSizeVideo;
    if (@available(iOS 9.1, *)) {
        predicate = (predicate || [self type] == PHAssetResourceTypePairedVideo);
    }
    if (@available(iOS 10.0, *)) {
        predicate = (predicate || [self type] == PHAssetResourceTypeFullSizePairedVideo);
        predicate = (predicate || [self type] == PHAssetResourceTypeAdjustmentBasePairedVideo);
    }
    if (@available(iOS 13.0, *)) {
        predicate = (predicate || [self type] == PHAssetResourceTypeAdjustmentBaseVideo);
    }
    return predicate;
}

- (bool)isAudio {
    return [self type] == PHAssetResourceTypeAudio;
}

- (bool)isImageOrVideo {
    return [self isVideo] || [self isImage];
}

- (bool)isValid {
    bool isResource = self.type != PHAssetResourceTypeAdjustmentData;
    
#if __IPHONE_17_0
    if (@available(iOS 17.0, *)) {
        isResource = isResource && self.type != PHAssetResourceTypePhotoProxy;
    }
#endif
    return isResource;
}

@end
