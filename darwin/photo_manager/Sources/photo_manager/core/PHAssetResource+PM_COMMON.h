//
//  PHAssetResource+PHAssetResource_checkType.h
//  photo_manager
//

#import <Photos/Photos.h>

@interface PHAssetResource (PM_COMMON)

- (bool)isImage;
- (bool)isVideo;
- (bool)isAudio;
- (bool)isImageOrVideo;
- (bool)isValid;

@end
