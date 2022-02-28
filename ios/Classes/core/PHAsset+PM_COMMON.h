//
//  PHAsset+PHAsset_checkType.h
//  photo_manager
//

#import <Photos/Photos.h>
#import <PMLogUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (PM_COMMON)

- (bool)isImage;
- (bool)isVideo;
- (bool)isAudio;
- (bool)isImageOrVideo;
- (bool)isLivePhoto;
- (int)unwrappedSubtype;

- (NSString*)title;
- (NSString*)mimeType;
- (BOOL)isAdjust;
- (PHAssetResource *)getAdjustResource;
- (void)requestAdjustedData:(void (^)(NSData *_Nullable result))block;
- (PHAssetResource *)getLivePhotosResource;

@end

NS_ASSUME_NONNULL_END
