#import "PMItemProviderAsset.h"
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@class PMResultHandler;
@class PMManager;

@interface PMItemProviderHelper : NSObject

- (void)handleItemProvider:(NSItemProvider *)itemProvider
                    result:(PHPickerResult *)result
                   manager:(PMManager *)manager
                  entities:(NSMutableArray<NSDictionary *> *)entities
        itemProviderAssets:(NSMutableArray<PMItemProviderAsset *> *)itemProviderAssets
                     group:(dispatch_group_t)group API_AVAILABLE(ios(14));

- (void)handleLivePhoto:(NSItemProvider *)itemProvider
                assetId:(NSString *)assetId
     itemProviderAssets:(NSMutableArray<PMItemProviderAsset *> *)itemProviderAssets
               entities:(NSMutableArray<NSDictionary *> *)entities
                  group:(dispatch_group_t)group;

- (void)handleImage:(NSItemProvider *)itemProvider
            assetId:(NSString *)assetId
 itemProviderAssets:(NSMutableArray<PMItemProviderAsset *> *)itemProviderAssets
           entities:(NSMutableArray<NSDictionary *> *)entities
              group:(dispatch_group_t)group;

- (void)handleVideo:(NSItemProvider *)itemProvider
            assetId:(NSString *)assetId
 itemProviderAssets:(NSMutableArray<PMItemProviderAsset *> *)itemProviderAssets
           entities:(NSMutableArray<NSDictionary *> *)entities
              group:(dispatch_group_t)group;

- (NSString *)copyToCache:(NSURL *)url assetId:(NSString *)assetId type:(NSString *)type;

@end
