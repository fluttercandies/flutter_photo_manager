//
//  PHAsset+PHAsset_checkType.h
//  photo_manager
//

#import <Photos/Photos.h>
#import "PMLogUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (PM_COMMON)

- (bool)isImage;
- (bool)isVideo;
- (bool)isAudio;
- (bool)isImageOrVideo;
- (bool)isLivePhoto;

- (NSString*)title;

- (NSString *)filenameWithOptions:(int)subtype isOrigin:(BOOL)isOrigin fileType:(AVFileType)fileType;

/**
 Get the MIME type for this asset from UTI (`PHAssetResource.uniformTypeIdentifier`), such as `image/jpeg`, `image/heic`, `video/quicktime`, etc.
 
 @note For Live Photos, this returns a type representing its image file.
 @return The MIME type of this asset if available, otherwise `nil`.
 */
- (nullable NSString*)mimeType;
- (PHAssetResource *)getCurrentResource;
- (void)requestCurrentResourceData:(void (^)(NSData *_Nullable result))block;

/// The base (unedited) resource of the asset, i.e. the original photo/video
/// before any Photos.app adjustments were applied. Falls back to
/// `getCurrentResource` when no distinct original resource exists.
- (PHAssetResource *)getOriginalResource;

/// The AAE adjustment-data resource (`PHAssetResourceTypeAdjustmentData`) that
/// stores the edit history applied in the Photos app, or `nil` when the asset
/// has no adjustments.
///
/// @note This resource is deliberately excluded by `getCurrentResource` /
/// `getOriginalResource`, so it must be fetched through this dedicated accessor.
- (nullable PHAssetResource *)getAdjustmentDataResource;

- (PHAssetResource *)getLivePhotosResource;

/// Ordered list of `PHAssetResource`s to try when exporting an asset's file.
///
/// PhotoKit exposes several resources per asset (original, adjusted, rendered,
/// paired video, ...) and any one of them can fail `writeDataForAssetResource`
/// with a generic `PHPhotosErrorInternalError` when iCloud has not fully
/// materialized that specific resource. Callers walk this list, retrying with
/// the next candidate on failure until one succeeds or the list is exhausted.
///
/// @param isOrigin  When `YES`, the caller wants the original (unedited) bytes;
///                  the returned order prefers the original resource type,
///                  then adjustment base, then the rendered/full-size variant.
///                  When `NO`, the caller wants the current rendered version
///                  and the order is reversed.
/// @param livePhoto When `YES`, resources for the Live Photo's paired video
///                  are returned instead of the primary photo/video resources.
- (NSArray<PHAssetResource *> *)candidateResourcesForFetch:(BOOL)isOrigin
                                                 livePhoto:(BOOL)livePhoto;

@end

NS_ASSUME_NONNULL_END
