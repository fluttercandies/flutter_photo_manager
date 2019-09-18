//
// Created by Caijinglong on 2019-09-06.
//

#import <Photos/Photos.h>
#import "ConvertUtils.h"
#import "PMAssetPathEntity.h"
#import "PHAsset+PHAsset_checkType.h"


@implementation ConvertUtils {

}
+ (NSDictionary *)convertPathToMap:(NSArray <PMAssetPathEntity *> *)array {
    NSMutableArray *data = [NSMutableArray new];

    for (PMAssetPathEntity *entity in array) {
        NSDictionary *item = @{
                @"id": entity.id,
                @"name": entity.name,
                @"length": @(entity.assetCount),
                @"isAll": @(entity.isAll),
        };

        [data addObject:item];
    }

    return @{@"data": data};
}

+ (NSDictionary *)convertAssetToMap:(NSArray<PMAssetEntity *> *)array {
    NSMutableArray *data = [NSMutableArray new];

    for (PMAssetEntity *asset in array) {
        NSDictionary *item = [ConvertUtils convertPMAssetToMap:asset];
        [data addObject:item];
    }


    return @{@"data": data};
}

+ (NSDictionary *)convertPHAssetToMap:(PHAsset *)asset {
    long createDt = (int) asset.creationDate.timeIntervalSince1970;
    long modifiedDt = (int) asset.modificationDate.timeIntervalSince1970;

    int typeInt = 0;

    if (asset.isVideo) {
        typeInt = 2;
    }
    if (asset.isImage) {
        typeInt = 1;
    }

    return @{
            @"id": asset.localIdentifier,
            @"createDt": @(createDt),
            @"width": @(asset.pixelWidth),
            @"height": @(asset.pixelHeight),
            @"duration": @((long) asset.duration),
            @"type": @(typeInt),
            @"modifiedDt": @(modifiedDt),
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
    };
}

@end