//
//  PHAsset+PHAsset_getTitle.m
//  photo_manager
//
//  Created by Caijinglong on 2020/1/15.
//

#import "PHAsset+PHAsset_getTitle.h"
#import "PHAsset+PHAsset_checkType.h"

@implementation PHAsset (PHAsset_getTitle)

- (NSString *)title {
  NSArray *array = [PHAssetResource assetResourcesForAsset:self];
  for (PHAssetResource *resource in array) {
    if ([self isImage] && resource.type == PHAssetResourceTypePhoto) {
      return resource.originalFilename;
    } else if ([self isVideo] && resource.type == PHAssetResourceTypeVideo) {
      return resource.originalFilename;
    }
  }

  /// If code run there, the type maybe have problem.
  /// Use first resource name.

  PHAssetResource *firstRes = array.firstObject;
  if (firstRes) {
    return firstRes.originalFilename;
  }

  return @"";
}

@end
