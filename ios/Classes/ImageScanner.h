//
// Created by Caijinglong on 2018/9/10.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <Photos/PHAsset.h>
#import <Photos/PHCollection.h>
#import "ScanForType.h"

typedef void (^asset_block)(PHCollection *collection, PHAsset *asset);
@class Reply;

@interface ImageScanner : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ScanForType> {

}
@property(nonatomic, strong) NSObject <FlutterPluginRegistrar> *registrar;

- (void)getGalleryIdList:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)requestPermissionWithResult:(FlutterResult)result;

- (void)getGalleryNameWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getImageListWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult;

- (void)getImageListPaged:(FlutterMethodCall *)call result:(FlutterResult)flutterResult;

- (void)filterAssetWithBlock:(asset_block)block;

- (void)forEachAssetCollection:(FlutterMethodCall *)call result:(FlutterResult)flutterResult;

- (void)getThumbPathWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult;

- (void)getBytesWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult reply:(Reply *)reply;

- (void)getFullFileWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult reply:(Reply *)reply;

+ (void)openSetting;

- (void)getThumbBytesWithCall:(FlutterMethodCall *)call result:(FlutterResult)result reply:(Reply *)reply;

- (void)getAssetTypeByIdsWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)isCloudWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getDurationWithId:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getSizeWithId:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)releaseMemCache:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)createAssetWithIdWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getTimeStampWithIdsWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)assetExistsWithId:(FlutterMethodCall *)call result:(FlutterResult)result;
@end
