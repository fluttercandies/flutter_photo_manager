//
//  AssetEntity.h
//  photo_manager
//

#import <Foundation/Foundation.h>
#import <Photos/PHAsset.h>

@interface AssetEntity : NSObject

@property(nonatomic,strong) PHAsset *asset;
@property(nonatomic, assign) BOOL isCloud;

@end
