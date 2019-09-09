//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>

@class PHAsset;


@interface PMAssetPathEntity : NSObject

@property(nonatomic, copy) NSString *id;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) int assetCount;
@property(nonatomic, assign) BOOL isAll;

- (instancetype)initWithId:(NSString *)id name:(NSString *)name assetCount:(int)assetCount;

+ (instancetype)entityWithId:(NSString *)id name:(NSString *)name assetCount:(int)assetCount;


@end


@interface PMAssetEntity : NSObject

@property(nonatomic, copy) NSString *id;
@property(nonatomic, assign) long createDt;
@property(nonatomic, assign) NSUInteger width;
@property(nonatomic, assign) NSUInteger height;
@property(nonatomic, assign) long duration;
@property(nonatomic, assign) int type;
@property(nonatomic, strong) PHAsset *phAsset;

- (instancetype)initWithId:(NSString *)id createDt:(long)createDt width:(NSUInteger)width height:(NSUInteger)height
                  duration:(long)duration type:(int)type;

+ (instancetype)entityWithId:(NSString *)id createDt:(long)createDt width:(NSUInteger)width height:(NSUInteger)height
                    duration:(long)duration type:(int)type;


@end