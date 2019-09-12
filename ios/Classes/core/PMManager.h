//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>

@class PMAssetPathEntity;
@class PMAssetEntity;
@class ResultHandler;

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
@end