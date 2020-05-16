//
//  PHAsset+PHAsset_getTitle.m
//  photo_manager
//
//  Created by Caijinglong on 2020/1/15.
//

#import "PHAsset+PHAsset_getTitle.h"
#import "PHAsset+PHAsset_checkType.h"
#import "PMLogUtils.h"

@implementation PHAsset (PHAsset_getTitle)

- (NSString *)title {
    PMLogUtils *logger = [PMLogUtils sharedInstance];
    NSLog(@"get title start");
    @try {
        NSString *result = [self valueForKey:@"filename"];
        [logger info:@"get title from kvo"];
        return result;
    } @catch (NSException *exception) {
        [logger info: @"get title from PHAssetResource"];
        NSArray *array = [PHAssetResource assetResourcesForAsset:self];
        for (PHAssetResource *resource in array) {
          if ([self isImage] && resource.type == PHAssetResourceTypePhoto) {
            return resource.originalFilename;
          } else if ([self isVideo] && resource.type == PHAssetResourceTypeVideo) {
            return resource.originalFilename;
          }
        }

        PHAssetResource *firstRes = array.firstObject;
        if (firstRes) {
          return firstRes.originalFilename;
        }

        return @"";
    }
}

@end
