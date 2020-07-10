//
//  PMResourceUtils.h
//  path_provider
//
//  Created by jinglong cai on 2020/7/10.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN

@interface PMResourceUtils : NSObject

-(NSNumber*) getPHAssetSize:(PHAsset*)asset;

@end

NS_ASSUME_NONNULL_END
