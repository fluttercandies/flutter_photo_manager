//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
@class PMAssetPathEntity;
@class PMAssetEntity;
@class PMFilterOption;


@interface ConvertUtils : NSObject

+ (NSDictionary *)convertPathToMap:(NSArray <PMAssetPathEntity *> *)array;

+ (NSDictionary *)convertAssetToMap:(NSArray<PMAssetEntity *> *)array;

+ (NSDictionary *)convertPHAssetToMap:(PHAsset *)asset;

+ (NSDictionary *)convertPMAssetToMap:(PMAssetEntity *)asset;

+ (PMFilterOption *)convertMapToPMFilterOption:(NSDictionary *)map;

@end
