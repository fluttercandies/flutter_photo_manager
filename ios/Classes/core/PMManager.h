//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>

@class PMAssetPathEntity;
@class PMAssetEntity;

@interface PMManager : NSObject

- (BOOL)isAuth;

- (void)setAuth:(BOOL)auth;

- (NSArray<PMAssetPathEntity *> *)getGalleryList:(int)type;

- (NSArray<PMAssetEntity *> *)getAssetEntityListWithGalleryId:(NSString *)id type:(int)type page:(NSUInteger)page
                                                    pageCount:(NSUInteger)pageCount;
@end