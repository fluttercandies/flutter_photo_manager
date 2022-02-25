//
//  PHAssetCollection+PHAssetCollection_obtainAssetCount.h
//  photo_manager
//
//  Created by Alex on 2022/2/24.
//

#import <Photos/Photos.h>

@interface PHAssetCollection (PHAssetCollection_obtainAssetCount)

- (NSUInteger)obtainAssetCount:(PHFetchOptions *)options;

@end
