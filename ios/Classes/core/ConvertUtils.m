//
// Created by Caijinglong on 2019-09-06.
//

#import "ConvertUtils.h"
#import "PHAsset+PHAsset_checkType.h"
#import "PHAsset+PHAsset_getTitle.h"
#import "PMAssetPathEntity.h"
#import "PMFilterOption.h"

@implementation ConvertUtils {
}

+ (NSDictionary *)convertPathToMap:(NSArray<PMAssetPathEntity *> *)array {
  NSMutableArray *data = [NSMutableArray new];

  for (PMAssetPathEntity *entity in array) {
    NSDictionary *item = @{
      @"id" : entity.id,
      @"name" : entity.name,
      @"length" : @(entity.assetCount),
      @"isAll" : @(entity.isAll),
    };

    [data addObject:item];
  }

  return @{@"data" : data};
}

+ (NSDictionary *)convertAssetToMap:(NSArray<PMAssetEntity *> *)array {
  NSMutableArray *data = [NSMutableArray new];

  for (PMAssetEntity *asset in array) {
    NSDictionary *item = [ConvertUtils convertPMAssetToMap:asset];
    [data addObject:item];
  }

  return @{@"data" : data};
}

+ (NSDictionary *)convertPHAssetToMap:(PHAsset *)asset {
  long createDt = (int)asset.creationDate.timeIntervalSince1970;
  long modifiedDt = (int)asset.modificationDate.timeIntervalSince1970;

  int typeInt = 0;

  if (asset.isVideo) {
    typeInt = 2;
  }
  if (asset.isImage) {
    typeInt = 1;
  }

  return @{
    @"id" : asset.localIdentifier,
    @"createDt" : @(createDt),
    @"width" : @(asset.pixelWidth),
    @"height" : @(asset.pixelHeight),
    @"duration" : @((long)asset.duration),
    @"type" : @(typeInt),
    @"modifiedDt" : @(modifiedDt),
    @"lng" : @(asset.location.coordinate.longitude),
    @"lat" : @(asset.location.coordinate.latitude),
    @"title" : [asset title],
  };
}

+ (NSDictionary *)convertPMAssetToMap:(PMAssetEntity *)asset {
  return @{
          @"id": asset.id,
          @"createDt": @(asset.createDt),
          @"width": @(asset.width),
          @"height": @(asset.height),
          @"duration": @(asset.duration),
          @"type": @(asset.type),
          @"modifiedDt": @(asset.modifiedDt),
          @"lng": @(asset.lng),
          @"lat": @(asset.lat),
          @"title": asset.title,
  };
}

+ (PMFilterOption *)convertMapToPMFilterOption:(NSDictionary *)map {
    PMFilterOption *option = [PMFilterOption new];
    option.needTitle = [map[@"title"] boolValue];

    NSDictionary *sizeMap = map[@"size"];
    NSDictionary *durationMap = map[@"duration"];

    PMSizeConstraint sizeConstraint;
    sizeConstraint.minWidth = [sizeMap[@"minWidth"] unsignedIntValue];
    sizeConstraint.maxWidth = [sizeMap[@"maxWidth"] unsignedIntValue];
    sizeConstraint.minHeight = [sizeMap[@"minHeight"] unsignedIntValue];
    sizeConstraint.maxHeight = [sizeMap[@"maxHeight"] unsignedIntValue];
    option.sizeConstraint = sizeConstraint;

    PMDurationConstraint durationConstraint;
    durationConstraint.minDuration = [ConvertUtils convertNSNumberToSecond:durationMap[@"min"]];
    durationConstraint.maxDuration = [ConvertUtils convertNSNumberToSecond:durationMap[@"max"]];
    option.durationConstraint = durationConstraint;

    return option;
}

+ (double)convertNSNumberToSecond:(NSNumber *)number {
    unsigned int i = number.unsignedIntValue;
    return (double) i / 1000.0;
}

@end
