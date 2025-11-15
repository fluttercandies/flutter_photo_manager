//
//  PHAssetCollection+PHAssetCollection_obtainAssetCount.m
//  photo_manager
//
//  Created by Alex on 2022/2/24.
//

#import "PHAssetCollection+PM_COMMON.h"

@implementation PHAssetCollection (PM_COMMON)

- (NSUInteger)obtainAssetCount:(PHFetchOptions *)options {
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:self options:options];
    NSUInteger count = fetchResult.count;
    return count;
}

@end
