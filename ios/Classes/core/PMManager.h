//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "PMFileHelper.h"

typedef void (^ChangeIds)(NSArray<NSString *> *);

@class PMAssetPathEntity;
@class PMAssetEntity;
@class ResultHandler;

typedef void (^AssetResult)(PMAssetEntity *);

@interface PMManager : NSObject

- (BOOL)isAuth;

+ (void)openSetting;

- (void)setAuth:(BOOL)auth;

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type date:(NSDate *)date hasAll:(BOOL)hasAll
                                          option:(PMFilterOption *)option;

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithGalleryId:(NSString *)id type:(int)type page:(NSUInteger)page
                                                    pageCount:(NSUInteger)pageCount date:(NSDate *)date
                                                 filterOption:(PMFilterOption *)filterOption;

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId;

- (void)clearCache;

- (void)getThumbWithId:(NSString *)id
                 width:(NSUInteger)width
                height:(NSUInteger)height
                format:(NSUInteger)format
         resultHandler:(ResultHandler *)handler;

- (void)getFullSizeFileWithId:(NSString *)id
                     isOrigin:(Boolean)isOrigin
                resultHandler:(ResultHandler *)handler;

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id type:(int)type date:(NSDate *)date
                              filterOption:(PMFilterOption *)filterOption;

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block;

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithRange:(NSString *)id type:(NSUInteger)type start:(NSUInteger)start
                                                      end:(NSUInteger)end date:(NSDate *)date
                                             filterOption:(PMFilterOption *)filterOption;

- (void)saveImage:(NSData *)data
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block;

- (void)saveVideo:(NSString *)path
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block;

- (BOOL)existsWithId:(NSString *)assetId;
@end
