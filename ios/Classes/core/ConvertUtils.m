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

    for (PMAssetEntity *entity in array) {
        NSDictionary *item = @{
                @"id": entity.id,
                @"createDt": @(entity.createDt),
                @"width": @(entity.width),
                @"height": @(entity.height),
                @"duration": @(entity.duration),
                @"type": @(entity.type),
        };

        [data addObject:item];
    }


    return @{@"data": data};
}

+ (NSDictionary *)convertPHAssetToMap:(PHAsset *)asset {
    int createDt = (int) (asset.creationDate.timeIntervalSince1970 / 1000);

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
    };
}

@end