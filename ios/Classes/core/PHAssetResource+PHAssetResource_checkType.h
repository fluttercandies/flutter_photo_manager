//
//  PHAssetResource+PHAssetResource_checkType.h
//  photo_manager
//

#import <Photos/Photos.h>

@interface PHAssetResource (PHAssetResource_checkType)

- (bool)isImage;
- (bool)isVideo;
- (bool)isAudio;
- (bool)isImageOrVideo;

@end
