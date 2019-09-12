//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>

@class PMAssetEntity;

@interface PMCacheContainer : NSObject

- (void)putAssetEntity:(PMAssetEntity *)entity;

- (PMAssetEntity *)getAssetEntity:(NSString *)id;

- (void)clearCache;
@end