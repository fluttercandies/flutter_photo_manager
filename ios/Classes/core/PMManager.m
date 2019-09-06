//
// Created by Caijinglong on 2019-09-06.
//

#import <Photos/Photos.h>
#import "PMManager.h"
#import "PMAssetPathEntity.h"
#import "PHAsset+PHAsset_checkType.h"


@implementation PMManager {
    BOOL __isAuth;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __isAuth = NO;
    }

    return self;
}


- (BOOL)isAuth {
    return __isAuth;
}

- (void)setAuth:(BOOL)auth {
    __isAuth = auth;
}

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type {
    NSMutableArray <PMAssetPathEntity *> *array = [NSMutableArray new];

    // type:
    // 0: all , 1: image, 2:video

    PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection
            fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                  subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                  options:[PHFetchOptions new]];

    PHFetchOptions *options = [PHFetchOptions new];
    if (type == 1) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    } else if (type == 2) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
    } else {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d OR mediaType == %d", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
    }

    for (PHAssetCollection *collection in result) {
        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];

        PMAssetPathEntity *entity = [PMAssetPathEntity
                entityWithId:collection.localIdentifier
                        name:collection.localizedTitle
                  assetCount:(int) fetchResult.count];
        [array addObject:entity];
    }

    return array;
}

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithGalleryId:(NSString *)id
                                                         type:(int)type
                                                         page:(NSUInteger)page
                                                    pageCount:(NSUInteger)pageCount {
    NSMutableArray<PMAssetEntity *> *result = [NSMutableArray new];

    PHFetchOptions *options = [PHFetchOptions new];

    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[id] options:options];
    if (fetchResult && fetchResult.count == 0) {
        return result;
    }

    if (type == 1) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    } else if (type == 2) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
    } else {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d OR mediaType == %d", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
    }

    PHAssetCollection *collection = fetchResult.firstObject;

    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];

    PHFetchResult<PHAsset *> *assetArray = [PHAsset fetchAssetsInAssetCollection:collection options:options];

    NSUInteger startIndex = page * pageCount;
    NSUInteger endIndex = startIndex + pageCount - 1;

    NSUInteger count = assetArray.count;
    if (endIndex >= count) {
        endIndex = count - 1;
    }

    for (NSUInteger i = startIndex; i <= endIndex; i++) {
        PHAsset *asset = assetArray[i];
        PMAssetEntity *entity = [self convertPHAssetToAssetEntity:asset];
        [result addObject:entity];
    }

    return result;
}

- (PMAssetEntity *)convertPHAssetToAssetEntity:(PHAsset *)asset {
    int type = 0;
    if (asset.isImage) {
        type = 1;
    } else if (asset.isVideo) {
        type = 2;
    }

    NSDate *date = asset.creationDate;
    long createDt = (long) (date.timeIntervalSince1970 / 1000);

    return [PMAssetEntity entityWithId:asset.localIdentifier createDt:createDt width:asset.pixelWidth height:asset.pixelHeight duration:(long) asset.duration type:type];
}

@end