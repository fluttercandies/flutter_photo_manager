//
// Created by Caijinglong on 2019-09-06.
//

#import <Photos/Photos.h>
#import "PMPlugin.h"
#import "PMManager.h"
#import "ResultHandler.h"
#import "ConvertUtils.h"
#import "PMAssetPathEntity.h"


@implementation PMPlugin {
}

- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"top.kikt/photo_manager" binaryMessenger:[registrar messenger]];
    PMPlugin *plugin = [PMPlugin new];
    [plugin setManager:[PMManager new]];
    [channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        [plugin onMethodCall:call result:result];
    }];
}

- (void)onMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    ResultHandler *handler = [ResultHandler handlerWithResult:result];
    PMManager *manager = self.manager;

    if ([call.method isEqualToString:@"requestPermission"]) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            BOOL auth = PHAuthorizationStatusAuthorized == status;
            [manager setAuth:auth];
            if (auth) {
                [handler reply:@1];
            } else {
                [handler reply:@0];
            }
        }];
    } else if (manager.isAuth) {
        [self onAuth:call result:result];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            BOOL auth = PHAuthorizationStatusAuthorized == status;
            [manager setAuth:auth];
            if (auth) {
                [self onAuth:call result:result];
            } else {
                [handler replyError:@"need permission"];
            }
        }];
    }
}

- (void)onAuth:(FlutterMethodCall *)call result:(FlutterResult)result {
    ResultHandler *handler = [ResultHandler handlerWithResult:result];
    PMManager *manager = self.manager;

    if ([call.method isEqualToString:@"getGalleryList"]) {

        int type = [call.arguments[@"type"] intValue];
        NSArray<PMAssetPathEntity *> *array = [manager getGalleryList:type];
        NSDictionary *dictionary = [ConvertUtils convertPathToMap:array];
        [handler reply:dictionary];

    } else if ([call.method isEqualToString:@"getAssetWithGalleryId"]) {

        NSString *id = call.arguments[@"id"];
        int type = [call.arguments[@"type"] intValue];
        NSUInteger page = [call.arguments[@"page"] unsignedIntValue];
        NSUInteger pageCount = [call.arguments[@"pageCount"] unsignedIntValue];
        NSArray<PMAssetEntity *> *array = [manager getAssetEntityListWithGalleryId:id type:type page:page pageCount:pageCount];
        NSDictionary *dictionary = [ConvertUtils convertAssetToMap:array];
        [handler reply:dictionary];

    } else if ([call.method isEqualToString:@"getThumb"]) {

    } else if ([call.method isEqualToString:@"getOrigin"]) {

    } else if ([call.method isEqualToString:@"releaseMemCache"]) {

    } else if ([call.method isEqualToString:@"log"]) {

    } else if ([call.method isEqualToString:@"openSetting"]) {

    }
}

@end