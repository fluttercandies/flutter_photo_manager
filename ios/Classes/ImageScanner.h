//
// Created by Caijinglong on 2018/9/10.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@class Reply;

@interface ImageScanner : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {

}
@property(nonatomic, strong) NSObject <FlutterPluginRegistrar> *registrar;

- (void)getGalleryIdList:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)requestPermissionWithResult:(FlutterResult)result;

- (void)getGalleryNameWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getImageListWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult;

- (void)getAllImageListWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult;

- (void)getThumbPathWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult;

- (void)getBytesWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult reply:(Reply *)reply;

- (void)getFullFileWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult reply:(Reply *)reply;

+ (void)openSetting;

- (void)getThumbBytesWithCall:(FlutterMethodCall *)call result:(FlutterResult)result reply:(Reply *)reply;

- (void)getAssetTypeByIdsWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)isCloudWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

-(void)getDurationWithId:(FlutterMethodCall *)call result:(FlutterResult)result;

@end
