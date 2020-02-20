//
// Created by Caijinglong on 2019-09-06.
//

#import "PMFileHelper.h"
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef void (^ChangeIds)(NSArray<NSString *> *);

@class PMAssetPathEntity;
@class PMAssetEntity;
@class ResultHandler;
@class PMFilterOption;
@class PMFilterOptionGroup;

typedef void (^AssetResult)(PMAssetEntity *);

@interface PMManager : NSObject

- (BOOL)isAuth;

+ (void)openSetting;

- (void)setAuth:(BOOL)auth;

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type
                                            date:(NSDate *)date
                                          hasAll:(BOOL)hasAll
                                          option:(PMFilterOptionGroup *)option;

- (NSArray<PMAssetEntity *> *)
getAssetEntityListWithGalleryId:(NSString *)id
                           type:(int)type
                           page:(NSUInteger)page
                      pageCount:(NSUInteger)pageCount
                           date:(NSDate *)date
                   filterOption:(PMFilterOptionGroup *)filterOption;

- (PMAssetEntity *)getAssetEntity:(NSString *)assetId needTitle:(BOOL)needTitle;

- (void)clearCache;

- (void)getThumbWithId:(NSString *)id
                 width:(NSUInteger)width
                height:(NSUInteger)height
                format:(NSUInteger)format
         resultHandler:(ResultHandler *)handler;

- (void)getFullSizeFileWithId:(NSString *)id
                     isOrigin:(BOOL)isOrigin
                resultHandler:(ResultHandler *)handler;

- (PMAssetPathEntity *)fetchPathProperties:(NSString *)id
                                      type:(int)type
                                      date:(NSDate *)date
                              filterOption:(PMFilterOptionGroup *)filterOption;

- (void)deleteWithIds:(NSArray<NSString *> *)ids changedBlock:(ChangeIds)block;

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithRange:(NSString *)id
                                                     type:(NSUInteger)type
                                                    start:(NSUInteger)start
                                                      end:(NSUInteger)end
                                                     date:(NSDate *)date
                                             filterOption:
                                                 (PMFilterOptionGroup *)filterOption;

- (void)saveImage:(NSData *)data
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block;

- (void)saveVideo:(NSString *)path
            title:(NSString *)title
             desc:(NSString *)desc
            block:(AssetResult)block;

- (BOOL)existsWithId:(NSString *)assetId;

- (NSString*)getTitleAsyncWithAssetId: (NSString *) assetId;

@end
