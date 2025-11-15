#import <Foundation/Foundation.h>

#define PM_TYPE_ALBUM 1
#define PM_TYPE_FOLDER 2
@class PHAsset;
@class PHAssetCollection;

@interface PMAssetPathEntity : NSObject

@property(nonatomic, copy) NSString *id;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) BOOL isAll;
@property(nonatomic, assign) int type;
@property(nonatomic, assign) NSUInteger assetCount;
@property(nonatomic, assign) long modifiedDate;
@property(nonatomic, strong) PHAssetCollection *collection;

+ (instancetype)entityWithId:(NSString *)id name:(NSString *)name assetCollection:(PHAssetCollection*)collection;

@end

@interface PMAssetEntity : NSObject

@property(nonatomic, copy) NSString *id;
@property(nonatomic, assign) long createDt;
@property(nonatomic, assign) NSUInteger width;
@property(nonatomic, assign) NSUInteger height;
@property(nonatomic, assign) long duration;
@property(nonatomic, assign) int type;
@property(nonatomic, strong) PHAsset *phAsset;
@property(nonatomic, assign) long modifiedDt;
@property(nonatomic, assign) double lat;
@property(nonatomic, assign) double lng;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, assign) NSUInteger subtype;
@property(nonatomic, assign) BOOL favorite;
@property(nonatomic, assign) BOOL isLocallyAvailable;

- (instancetype)initWithId:(NSString *)id
                  createDt:(long)createDt
                     width:(NSUInteger)width
                    height:(NSUInteger)height
                  duration:(long)duration
                      type:(int)type;

+ (instancetype)entityWithId:(NSString *)id
                    createDt:(long)createDt
                       width:(NSUInteger)width
                      height:(NSUInteger)height
                    duration:(long)duration
                        type:(int)type;

@end
