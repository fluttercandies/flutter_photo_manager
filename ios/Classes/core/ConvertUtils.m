//
// Created by Caijinglong on 2019-09-06.
//

#import "ConvertUtils.h"
#import "PMAssetPathEntity.h"


@implementation ConvertUtils {

}
+ (NSDictionary *)convertPathToMap:(NSArray <PMAssetPathEntity *> *)array {
    NSMutableArray *data = [NSMutableArray new];

    for (PMAssetPathEntity *entity in array) {
        NSDictionary *item = @{
                @"id": entity.id,
                @"name": entity.name,
                @"length": @(entity.assetCount),
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
@end