//
//  PMResourceUtils.m
//  path_provider
//
//  Created by jinglong cai on 2020/7/10.
//

#import "PMResourceUtils.h"

@implementation PMResourceUtils

-(NSNumber *)getPHAssetSize:(PHAsset *)asset {
    NSArray<PHAssetResource *> *res = [PHAssetResource assetResourcesForAsset:asset];
    return [res.firstObject valueForKey:@"fileSize"];
}

@end
