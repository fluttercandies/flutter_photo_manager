#import "PMFileHelper.h"
#import "PMImport.h"
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef void (^ChangeIds)(NSArray<NSString *> *);

@class PMAssetPathEntity;
@class PMAssetEntity;
@class ResultHandler;
@class PMFilterOption;
@class PMFilterOptionGroup;
@class PMThumbLoadOption;
@class PMPathFilterOption;

#import "PMProgressHandlerProtocol.h"
#import "PMResultHandler.h"
#import "PMConvertProtocol.h"

#define PM_VIDEO_CACHE_PATH @".video"
#define PM_IMAGE_CACHE_PATH @".image"
#define PM_FULL_IMAGE_CACHE_PATH @"flutter-images"

typedef void (^AssetResult)(PMAssetEntity *);


@interface PMManager : NSObject

@property(nonatomic, strong) NSObject <PMConvertProtocol> *converter;

+ (void)openSetting:(NSObject<PMResultHandler>*)result;

- (NSArray<PMAssetPathEntity *> *)getAssetPathList:(int)type hasAll:(BOOL)hasAll onlyAll:(BOOL)onlyAll option:(NSObject <PMBaseFilter> *)option pathFilterOption:(PMPathFilterOption *)pathFilterOption;

- (NSUInteger)getAssetCountFromPath:(NSString *)id type:(int)type filterOption:(NSObject<PMBaseFilter> *)filterOption;

- (NSArray<PMAssetEntity *> *)getAssetListPaged:(NSString *)id type:(int)type page:(NSUInteger)page size:(NSUInteger)size filterOption:(NSObject<PMBaseFilter> *)filterOption;

- (NSArray<PMAssetEntity *> *)getAssetListRange:(NSString *)id type:(int)type start:(NSUInteger)start end:(NSUInteger)end filterOption:(NSObject<PMBaseFilter> *)filterOption;

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId;

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId withCache:(BOOL)withCache;

- (void)clearCache;

- (void)getThumbWithId:(NSString *)id option:(PMThumbLoadOption *)option resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler;

- (void)getFullSizeFileWithId:(NSString *)id isOrigin:(BOOL)isOrigin subtype:(int)subtype resultHandler:(NSObject <PMResultHandler> *)handler progressHandler:(NSObject <PMProgressHandlerProtocol> *)progressHandler;

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id type:(int)type filterOption:(NSObject<PMBaseFilter> *)filterOption;

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block;

- (void)saveImage:(NSData *)data
            title:(NSString *)title
            desc:(NSString *)desc
            block:(AssetResult)block;

- (void)saveVideo:(NSString *)path
            title:(NSString *)title
            desc:(NSString *)desc
            block:(AssetResult)block;

- (void)saveLivePhoto:(NSString *)imagePath
            videoPath:(NSString *)videoPath
            title:(NSString *)title
            desc:(NSString *)desc
            block:(AssetResult)block;

- (BOOL)existsWithId:(NSString *)assetId;

- (BOOL)entityIsLocallyAvailable:(NSString *)assetId resource:(PHAssetResource *)resource isOrigin:(BOOL)isOrigin;

- (NSString*)getTitleAsyncWithAssetId:(NSString *)assetId subtype:(int)subtype;

- (NSString*)getMimeTypeAsyncWithAssetId: (NSString *) assetId;

- (void)getMediaUrl:(NSString *)assetId resultHandler:(NSObject <PMResultHandler> *)handler;

- (NSArray<PMAssetPathEntity *> *)getSubPathWithId:(NSString *)id type:(int)type albumType:(int)albumType option:(NSObject<PMBaseFilter> *)option;

- (void)saveImageWithPath:(NSString *)path title:(NSString *)title desc:(NSString *)desc block:(void (^)(PMAssetEntity *))block;

- (void)copyAssetWithId:(NSString *)id toGallery:(NSString *)gallery block:(void (^)(PMAssetEntity *entity, NSString *msg))block;

- (void)createFolderWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *, NSString *))block;

- (void)createAlbumWithName:(NSString *)name parentId:(NSString *)id block:(void (^)(NSString *, NSString *))block;

- (void)removeInAlbumWithAssetId:(NSArray *)id albumId:(NSString *)albumId block:(void (^)(NSString *))block;

- (void)removeCollectionWithId:(NSString *)id type:(int)type block:(void (^)(NSString *))block;

- (BOOL)favoriteWithId:(NSString *)id favorite:(BOOL)favorite;

- (void)clearFileCache;

- (void)requestCacheAssetsThumb:(NSArray *)identifiers option:(PMThumbLoadOption *)option;

- (void)cancelCacheRequests;

- (void)injectModifyToDate:(PMAssetPathEntity *)path;

- (NSUInteger) getAssetCountWithType:(int)type option:(NSObject<PMBaseFilter> *) filter;

- (NSArray<PMAssetEntity*>*) getAssetsWithType:(int)type option:(NSObject<PMBaseFilter> *)option start:(int)start end:(int)end;

@end
