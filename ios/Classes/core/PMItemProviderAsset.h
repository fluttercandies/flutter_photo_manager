#import <Foundation/Foundation.h>

@interface PMItemProviderAsset : NSObject <NSSecureCoding>

@property(nonatomic, copy) NSString *id;
@property(nonatomic, assign) long createDt;
@property(nonatomic, assign) NSUInteger width;
@property(nonatomic, assign) NSUInteger height;
@property(nonatomic, assign) long duration;
@property(nonatomic, assign) int type;
@property(nonatomic, assign) int subtype;
@property(nonatomic, copy) NSString *path;

- (instancetype)initWithId:(NSString *)id
                  createDt:(long)createDt
                     width:(NSUInteger)width
                    height:(NSUInteger)height
                  duration:(long)duration
                      type:(int)type
                   subtype:(int)subtype
                      path:(NSString *)path;

+ (instancetype)assetWithId:(NSString *)id
                   createDt:(long)createDt
                      width:(NSUInteger)width
                     height:(NSUInteger)height
                   duration:(long)duration
                       type:(int)type
                    subtype:(int)subtype
                       path:(NSString *)path;

@end
