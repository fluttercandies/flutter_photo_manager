//
//  PHAssetCollection+PHAssetCollection_obtainAssetCount.m
//  photo_manager
//
//  Created by Alex on 2022/2/24.
//

#import "PHAssetCollection+PM_COMMON.h"

@implementation PHAssetCollection (PM_COMMON)

- (NSUInteger)obtainAssetCount:(PHFetchOptions *)options {
    NSUInteger count = self.estimatedAssetCount;
    if (count == NSNotFound) {
        PHFetchResult<PHAsset *> *fetchResult =
        [PHAsset fetchAssetsInAssetCollection:self
                                      options:options];
        count = fetchResult.count;
    }
    return count;
}

@end
