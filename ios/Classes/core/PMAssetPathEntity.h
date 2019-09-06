//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>


@interface PMAssetPathEntity : NSObject

@property(nonatomic, copy) NSString *id;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) int assetCount;

- (instancetype)initWithId:(NSString *)id name:(NSString *)name assetCount:(int)assetCount;

+ (instancetype)entityWithId:(NSString *)id name:(NSString *)name assetCount:(int)assetCount;


@end


@interface PMAssetEntity : NSObject

@property(nonatomic, copy) NSString *id;
@property(nonatomic, assign) long createDt;
@property(nonatomic, assign) int width;
@property(nonatomic, assign) int height;
@property(nonatomic, assign) long duration;
@property(nonatomic, assign) int type;

- (instancetype)initWithId:(NSString *)id createDt:(long)createDt width:(int)width height:(int)height
                  duration:(long)duration type:(int)type;

+ (instancetype)entityWithId:(NSString *)id createDt:(long)createDt width:(int)width height:(int)height
                    duration:(long)duration type:(int)type;


@end