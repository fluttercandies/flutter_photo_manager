#import "PMFolderUtils.h"
#import "PMLogUtils.h"

@implementation PMFolderUtils {
    
}

+ (NSArray<PHCollectionList *> *)getRootFolderWithOptions:(PHFetchOptions *)options {
    PHFetchResult<PHCollection *> *result = [PHCollection fetchTopLevelUserCollectionsWithOptions:options];
    
    NSMutableArray *array = [NSMutableArray new];
    
    for (PHCollection *item in result) {
        if ([item isMemberOfClass:PHCollectionList.class]) {
            [array addObject:item];
        }
    }
    
    return array;
}

+ (BOOL)isRecentCollection:(NSString *)id {
    // iOS 18 tightened `fetchAssetCollectionsWithType:subtype:` to raise
    // "Unsupported fetch for asset collections with type 2 and subtype 2"
    // for the (SmartAlbum, AlbumRegular) combination that older releases
    // silently tolerated. AlbumRegular is a subtype of the Album *type*,
    // never SmartAlbum, so the previous call was already meaningless — we
    // just want the user's primary library, which is exactly what
    // `SmartAlbumUserLibrary` targets.
    PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection
                                                  fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                  subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                  options:nil];

    for (PHAssetCollection *collection in result) {
        if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
            return [id isEqualToString:collection.localIdentifier];
        }
    }

    return NO;
}

+ (NSArray <PHCollection *> *)getSubCollectionWithCollection:(PHCollectionList *)collection
                                                     options:(PHFetchOptions *)options {
    
    PHFetchResult<PHCollection *> *result = [PHCollection fetchCollectionsInCollectionList:collection options:nil];
    
    NSMutableArray *array = [NSMutableArray new];
    
    for (PHCollection *item in result) {
        if ([item isMemberOfClass:PHCollectionList.class] || [item isMemberOfClass:PHAssetCollection.class]) {
            [array addObject:item];
        }
    }
    
    return array;
}

+ (void)debugInfo:(PHCollection *)collection {
    NSString *title = collection.localizedTitle;
    if ([collection isMemberOfClass:PHCollectionList.class]) {
        [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"title = %@, type: %@", title, @"文件夹"]];
    } else {
        [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"title = %@, type: %@", title, @"相簿"]];
    }
}


@end
