//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef void(^ChangeIds)(NSArray<NSString *> *);

@class PMAssetPathEntity;
@class PMAssetEntity;
@class ResultHandler;

typedef void(^AssetResult)(PMAssetEntity *);

@interface PMManager : NSObject

- (BOOL)isAuth;

+ (void)openSetting;

- (void)setAuth:(BOOL)auth;

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type date:(NSDate *)date hasAll:(BOOL)hasAll;

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithGalleryId:(NSString *)id type:(int)type page:(NSUInteger)page
                                                    pageCount:(NSUInteger)pageCount date:(NSDate *)date;

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId;

- (void)clearCache;

- (void)getThumbWithId:(NSString *)id width:(NSUInteger)width height:(NSUInteger)height
         resultHandler:(ResultHandler *)handler;

- (void)getFullSizeFileWithId:(NSString *)id resultHandler:(ResultHandler *)handler;

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id type:(int)type date:(NSDate *)date;

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block;

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithRange:(NSString *)id type:(NSUInteger)type start:(NSUInteger)start
                                                      end:(NSUInteger)end date:(NSDate *)date;

- (void)saveImage:(NSData *)data title:(NSString *)title desc:(NSString *)desc block:(AssetResult)block;

- (void)saveVideo:(NSString *)path title:(NSString *)title desc:(NSString *)desc block:(AssetResult)block;

- (BOOL)existsWithId:(NSString *) assetId;
@end

