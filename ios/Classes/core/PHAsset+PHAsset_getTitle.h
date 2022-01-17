//
//  PHAsset+PHAsset_getTitle.h
//  photo_manager
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN


@interface PHAsset (PHAsset_getTitle)

- (NSString*)title;

- (BOOL)isAdjust;

- (PHAssetResource *)getAdjustResource;

- (void)requestAdjustedData:(void (^)(NSData *_Nullable result))block;

- (PHAssetResource *)getLivePhotosResource;

@end

NS_ASSUME_NONNULL_END
