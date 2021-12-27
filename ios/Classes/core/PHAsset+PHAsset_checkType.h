//
//  PHAsset+PHAsset_checkType.h
//  photo_manager
//

#import <Photos/Photos.h>

@interface PHAsset (PHAsset_checkType)

- (bool)isImage;
- (bool)isVideo;
- (bool)isAudio;
- (bool)isImageOrVideo;
- (bool)isLivePhoto;
- (int)unwrappedSubtype;

@end
