#import "PMPlugin.h"
#import "PMConvertUtils.h"
#import "PMAssetPathEntity.h"
#import "PMLogUtils.h"
#import "PMManager.h"
#import "PMNotificationManager.h"
#import "ResultHandler.h"
#import "PMThumbLoadOption.h"
#import "PMProgressHandler.h"
#import "PMConverter.h"
#import "PMPathFilterOption.h"

#import <PhotosUI/PhotosUI.h>

@implementation PMPlugin {
    BOOL ignoreCheckPermission;
    NSObject <FlutterPluginRegistrar> *privateRegistrar;
}

- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar {
    privateRegistrar = registrar;
    [self initNotificationManager:registrar];

    FlutterMethodChannel *channel =
        [FlutterMethodChannel methodChannelWithName:@"com.fluttercandies/photo_manager"
                                    binaryMessenger:[registrar messenger]];
    PMManager *manager = [PMManager new];
    manager.converter = [PMConverter new];
    [self setManager:manager];
    [channel
        setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
          [self onMethodCall:call result:result];
        }];
}

- (void)initNotificationManager:(NSObject <FlutterPluginRegistrar> *)registrar {
    self.notificationManager = [PMNotificationManager managerWithRegistrar:registrar];
}

- (void) requestOnlyAddPermission:(void(^)(PHAuthorizationStatus status))handler {
#if TARGET_OS_OSX
    if (@available(macOS 11.0, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly handler:handler];
    } else {
        [PHPhotoLibrary requestAuthorization: handler];
    }
#endif

#if TARGET_OS_IOS
    if (@available(iOS 14.0, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly handler:handler];
    } else {
        [PHPhotoLibrary requestAuthorization: handler];
    }
#endif
}


- (void)requestPermissionForWriteAndRead:(void (^)(BOOL auth))handler {
#if TARGET_OS_OSX
    if (@available(macOS 11.0, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
          handler(status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited);
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
          handler(status == PHAuthorizationStatusAuthorized);
        }];
    }
#endif

#if TARGET_OS_IOS
    if (@available(iOS 14.0, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
          handler(status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited);
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
          handler(status == PHAuthorizationStatusAuthorized);
        }];
    }
#endif
}

- (BOOL)isNotNeedPermissionMethod:(NSString *)method {
    return [@[@"log", @"openSetting", @"clearFileCache", @"releaseMemoryCache", @"ignorePermissionCheck"] indexOfObject:method] != NSNotFound;
}

- (BOOL)isAboutPermissionMethod:(NSString *)method {
    return [@[@"presentLimited", @"requestPermissionExtend"] indexOfObject:method] != NSNotFound;
}

- (void)onMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    ResultHandler *handler = [ResultHandler handlerWithCall:call result:result];

    if ([self isNotNeedPermissionMethod:call.method]) {
        [self handleNotNeedPermissionMethod:handler];
    } else if ([self isAboutPermissionMethod:call.method]) {
        [self handleAboutPermissionMethod:handler];
    } else {
        [self onAuth:handler];
    }
}

- (void)handleNotNeedPermissionMethod:(ResultHandler *)handler {
    FlutterMethodCall *call = handler.call;
    NSString *method = call.method;
    PMManager *manager = self.manager;

    if ([method isEqualToString:@"clearFileCache"]) {
        [manager clearFileCache];
        [handler reply:@1];
    } else if ([method isEqualToString:@"openSetting"]) {
        [PMManager openSetting:handler];
    } else if ([method isEqualToString:@"ignorePermissionCheck"]) {
        ignoreCheckPermission = [call.arguments[@"ignore"] boolValue];
        [handler reply:@(ignoreCheckPermission)];
    } else if ([method isEqualToString:@"log"]) {
        PMLogUtils.sharedInstance.isLog = [call.arguments boolValue];
        [handler reply:@1];
    } else if ([call.method isEqualToString:@"releaseMemoryCache"]) {
        [manager clearCache];
        [handler reply:nil];
    }
}

- (void)handleAboutPermissionMethod:(ResultHandler *)handler {
    FlutterMethodCall *call = handler.call;
    PMManager *manager = self.manager;

    if ([call.method isEqualToString:@"requestPermissionExtend"]) {
        int requestAccessLevel = [call.arguments[@"iosAccessLevel"] intValue];
        [self handlePermission:manager handler:handler requestAccessLevel:requestAccessLevel];
    } else if ([call.method isEqualToString:@"presentLimited"]) {
        [self presentLimited:handler];
    }
}

- (void)replyPermssionResult:(ResultHandler *)handler status:(PHAuthorizationStatus)status isOnlyAdd:(BOOL)isOnlyAdd {
    [handler reply:@(status)];
}

#if TARGET_OS_IOS
#if __IPHONE_14_0

- (UIViewController *)getCurrentViewController {
    UIViewController *controller = UIApplication.sharedApplication.keyWindow.rootViewController;
    if (controller) {
        UIViewController *result = controller;
        while (1) {
            if (result.presentedViewController) {
                result = result.presentedViewController;
            } else {
                return result;
            }
        }
    }
    return nil;
}

#endif

- (void)handlePermission:(PMManager *)manager
                 handler:(ResultHandler *)handler
      requestAccessLevel:(int)requestAccessLevel {
#if __IPHONE_14_0
    if (@available(iOS 14, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:requestAccessLevel handler:^(PHAuthorizationStatus status) {
          [self replyPermssionResult:handler status:status isOnlyAdd: (requestAccessLevel == PHAccessLevelAddOnly)];
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
          [self replyPermssionResult:handler status:status isOnlyAdd:NO];
        }];
    }
#else
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        [self replyPermssionResult:handler status:status];
    }];
#endif
}

- (void)requestPermissionStatus:(int)requestAccessLevel
                completeHandler:(void (^)(PHAuthorizationStatus status))completeHandler {
#if __IPHONE_14_0
    if (@available(iOS 14, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:requestAccessLevel handler:^(PHAuthorizationStatus status) {
          completeHandler(status);
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
          completeHandler(status);
        }];
    }
#else
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        completeHandler(status);
    }];
#endif
}

- (void)presentLimited:(ResultHandler *)handler {
#if __IPHONE_14_0
    if (@available(iOS 14, *)) {
        UIViewController *controller = [self getCurrentViewController];
        if (!controller) {
            [handler reply:[FlutterError
                errorWithCode:@"UIViewController is nil"
                      message:@"presentLimited require a valid UIViewController."
                      details:nil]];
            return;
        }
#if __IPHONE_15_0
        if (@available(iOS 15, *)) {
            [PHPhotoLibrary.sharedPhotoLibrary
                presentLimitedLibraryPickerFromViewController:controller
                                            completionHandler:^(NSArray<NSString *> *_Nonnull list) {
                                              [handler reply:list];
                                            }];
        } else {
            [PHPhotoLibrary.sharedPhotoLibrary presentLimitedLibraryPickerFromViewController:controller];
            [handler reply:nil];
        }
#else
        [PHPhotoLibrary.sharedPhotoLibrary presentLimitedLibraryPickerFromViewController: controller];
        [handler reply:nil];
#endif
        return;
    }
#else
    [handler reply:nil];
#endif
}

#endif

#if TARGET_OS_OSX
- (void)handlePermission:(PMManager *)manager
                 handler:(ResultHandler*)handler
      requestAccessLevel:(int)requestAccessLevel {
#if __MAC_11_0
    if (@available(macOS 11.0, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:requestAccessLevel handler:^(PHAuthorizationStatus status) {
            [self replyPermssionResult:handler status:status isOnlyAdd:(requestAccessLevel == PHAccessLevelAddOnly)];
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            [self replyPermssionResult:handler status:status isOnlyAdd:NO];
        }];
    }
#else
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        [self replyPermssionResult:handler status:status isOnlyAdd:NO];
    }];
#endif
}

- (void)requestPermissionStatus:(int)requestAccessLevel
                completeHandler:(void (^)(PHAuthorizationStatus status))completeHandler {
#if __MAC_11_0
    if (@available(macOS 11.0, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:requestAccessLevel handler:^(PHAuthorizationStatus status) {
            completeHandler(status);
        }];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            completeHandler(status);
        }];
    }
#else
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        completeHandler(status);
    }];
#endif
}

- (void)presentLimited:(ResultHandler*)handler {
    [handler replyError:@"Not supported on macOS."];
}

#endif

- (void)runInBackground:(dispatch_block_t)block {
    dispatch_async(dispatch_get_global_queue(0, 0), block);
}

- (void)onAuth:(ResultHandler *)handler {
    PMManager *manager = self.manager;
    __block PMNotificationManager *notificationManager = self.notificationManager;

    [self runInBackground:^{
      @try {
          [self handleMethodResultHandler:handler manager:manager notificationManager:notificationManager];
      }
      @catch (NSException *exception) {
          [handler replyError:exception.reason];
      }
    }];
}

- (void)handleMethodResultHandler:(ResultHandler *)handler manager:(PMManager *)manager notificationManager:(PMNotificationManager *)notificationManager {
    FlutterMethodCall *call = handler.call;

    if ([call.method isEqualToString:@"getAssetPathList"]) {
        int type = [call.arguments[@"type"] intValue];
        BOOL hasAll = [call.arguments[@"hasAll"] boolValue];
        BOOL onlyAll = [call.arguments[@"onlyAll"] boolValue];
        NSObject <PMBaseFilter> *option =
            [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];

        PMPathFilterOption *pathFilterOption = [PMPathFilterOption optionWithDict:call.arguments[@"pathOption"]];

        NSArray<PMAssetPathEntity *> *array = [manager getAssetPathList:type hasAll:hasAll onlyAll:onlyAll option:option pathFilterOption:pathFilterOption];
        NSDictionary *dictionary = [PMConvertUtils convertPathToMap:array];
        [handler reply:dictionary];
    } else if ([call.method isEqualToString:@"getAssetCountFromPath"]) {
        NSString *id = call.arguments[@"id"];
        int requestType = [call.arguments[@"type"] intValue];
        NSObject <PMBaseFilter> *option =
            [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        NSUInteger assetCount = [manager getAssetCountFromPath:id
                                                          type:requestType
                                                  filterOption:option];
        [handler reply:@(assetCount)];
    } else if ([call.method isEqualToString:@"getAssetListPaged"]) {
        NSString *id = call.arguments[@"id"];
        int type = [call.arguments[@"type"] intValue];
        NSUInteger page = [call.arguments[@"page"] unsignedIntValue];
        NSUInteger size = [call.arguments[@"size"] unsignedIntValue];
        NSObject <PMBaseFilter> *option =
            [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        NSArray<PMAssetEntity *> *array =
            [manager getAssetListPaged:id type:type page:page size:size filterOption:option];
        NSDictionary *dictionary =
            [PMConvertUtils convertAssetToMap:array optionGroup:option];
        [handler reply:dictionary];
    } else if ([call.method isEqualToString:@"getAssetListRange"]) {
        NSString *id = call.arguments[@"id"];
        int type = [call.arguments[@"type"] intValue];
        NSUInteger start = [call.arguments[@"start"] unsignedIntegerValue];
        NSUInteger end = [call.arguments[@"end"] unsignedIntegerValue];
        NSObject <PMBaseFilter> *option =
            [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        NSArray<PMAssetEntity *> *array =
            [manager getAssetListRange:id type:type start:start end:end filterOption:option];
        NSDictionary *dictionary =
            [PMConvertUtils convertAssetToMap:array optionGroup:option];
        [handler reply:dictionary];
    } else if ([call.method isEqualToString:@"getThumb"]) {
        NSString *id = call.arguments[@"id"];
        NSDictionary *dict = call.arguments[@"option"];
        PMProgressHandler *progressHandler = [self getProgressHandlerFromDict:call.arguments];
        PMThumbLoadOption *option = [PMThumbLoadOption optionDict:dict];
        [manager getThumbWithId:id
                         option:option
                  resultHandler:handler
                progressHandler:progressHandler];
    } else if ([call.method isEqualToString:@"getFullFile"]) {
        NSString *id = call.arguments[@"id"];
        BOOL isOrigin = [call.arguments[@"isOrigin"] boolValue];
        int subtype = [call.arguments[@"subtype"] intValue];
        PMProgressHandler *progressHandler = [self getProgressHandlerFromDict:call.arguments];
        [manager getFullSizeFileWithId:id
                              isOrigin:isOrigin
                               subtype:subtype
                         resultHandler:handler
                       progressHandler:progressHandler];
    } else if ([call.method isEqualToString:@"fetchPathProperties"]) {
        NSString *id = call.arguments[@"id"];
        int requestType = [call.arguments[@"type"] intValue];
        NSObject <PMBaseFilter> *option =
            [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        PMAssetPathEntity *pathEntity = [manager fetchPathProperties:id
                                                                type:requestType
                                                        filterOption:option];
        if (option.containsModified) {
            [manager injectModifyToDate:pathEntity];
        }
        if (pathEntity) {
            NSDictionary *dictionary =
                [PMConvertUtils convertPathToMap:@[pathEntity]];
            [handler reply:dictionary];
        } else {
            [handler reply:nil];
        }
    } else if ([call.method isEqualToString:@"notify"]) {
        BOOL notify = [call.arguments[@"notify"] boolValue];
        if (notify) {
            [notificationManager startNotify];
        } else {
            [notificationManager stopNotify];
        }
        [handler reply:nil];
    } else if ([call.method isEqualToString:@"isNotifying"]) {
        BOOL isNotifying = [notificationManager isNotifying];
        [handler reply:@(isNotifying)];

    } else if ([call.method isEqualToString:@"deleteWithIds"]) {
        NSArray<NSString *> *ids = call.arguments[@"ids"];
        [manager deleteWithIds:ids
                  changedBlock:^(NSArray<NSString *> *array) {
                    [handler reply:array];
                  }];
    } else if ([call.method isEqualToString:@"saveImage"]) {
        NSData *data = [call.arguments[@"image"] data];
        NSString *title = call.arguments[@"title"];
        NSString *desc = call.arguments[@"desc"];
        [manager saveImage:data
                     title:title
                      desc:desc
                     block:^(PMAssetEntity *asset) {
                       if (!asset) {
                           [handler reply:nil];
                           return;
                       }
                       [handler reply:[PMConvertUtils convertPMAssetToMap:asset needTitle:NO]];
                     }];
    } else if ([call.method isEqualToString:@"saveImageWithPath"]) {
        NSString *path = call.arguments[@"path"];
        NSString *title = call.arguments[@"title"];
        NSString *desc = call.arguments[@"desc"];
        [manager saveImageWithPath:path
                             title:title
                              desc:desc
                             block:^(PMAssetEntity *asset) {
                               if (!asset) {
                                   [handler reply:nil];
                                   return;
                               }
                               [handler reply:[PMConvertUtils convertPMAssetToMap:asset needTitle:NO]];
                             }];
    } else if ([call.method isEqualToString:@"saveVideo"]) {
        NSString *videoPath = call.arguments[@"path"];
        NSString *title = call.arguments[@"title"];
        NSString *desc = call.arguments[@"desc"];
        [manager saveVideo:videoPath
                     title:title
                      desc:desc
                     block:^(PMAssetEntity *asset) {
                       if (!asset) {
                           [handler reply:nil];
                           return;
                       }
                       [handler reply:[PMConvertUtils convertPMAssetToMap:asset needTitle:NO]];
                     }];
    } else if ([call.method isEqualToString:@"saveLivePhoto"]) {
        NSString *videoPath = call.arguments[@"videoPath"];
        NSString *imagePath = call.arguments[@"imagePath"];
        NSString *title = call.arguments[@"title"];
        NSString *desc = call.arguments[@"desc"];
        [manager saveLivePhoto:imagePath
                     videoPath:videoPath
                         title:title
                          desc:desc
                         block:^(PMAssetEntity *asset) {
                           if (!asset) {
                               [handler reply:nil];
                               return;
                           }
                           [handler reply:[PMConvertUtils convertPMAssetToMap:asset needTitle:NO]];
                         }];
    } else if ([call.method isEqualToString:@"assetExists"]) {
        NSString *assetId = call.arguments[@"id"];
        BOOL exists = [manager existsWithId:assetId];
        [handler reply:@(exists)];
    } else if ([call.method isEqualToString:@"isLocallyAvailable"]) {
        NSString *assetId = call.arguments[@"id"];
        BOOL isOrigin = [call.arguments[@"isOrigin"] boolValue];
        BOOL exists = [manager entityIsLocallyAvailable:assetId resource:nil isOrigin:isOrigin];
        [handler reply:@(exists)];
    } else if ([call.method isEqualToString:@"getTitleAsync"]) {
        NSString *assetId = call.arguments[@"id"];
        int subtype = [call.arguments[@"subtype"] intValue];
        NSString *title = [manager getTitleAsyncWithAssetId:assetId subtype:subtype];
        [handler reply:title];
    } else if ([call.method isEqualToString:@"getMimeTypeAsync"]) {
        NSString *assetId = call.arguments[@"id"];
        NSString *mimeType = [manager getMimeTypeAsyncWithAssetId:assetId];
        [handler reply:mimeType];
    } else if ([@"getMediaUrl" isEqualToString:call.method]) {
        [manager getMediaUrl:call.arguments[@"id"] resultHandler:handler];
    } else if ([@"fetchEntityProperties" isEqualToString:call.method]) {
        NSString *assetId = call.arguments[@"id"];
        PMAssetEntity *entity = [manager getAssetEntity:assetId withCache:NO];
        if (entity == nil) {
            [handler reply:nil];
            return;
        }
        [handler reply:[PMConvertUtils convertPMAssetToMap:entity needTitle:YES]];
    } else if ([@"getSubPath" isEqualToString:call.method]) {
        NSString *galleryId = call.arguments[@"id"];
        int type = [call.arguments[@"type"] intValue];
        int albumType = [call.arguments[@"albumType"] intValue];
        NSDictionary *optionMap = call.arguments[@"option"];
        NSObject <PMBaseFilter> *option = [PMConvertUtils convertMapToOptionContainer:optionMap];

        NSArray<PMAssetPathEntity *> *array = [manager getSubPathWithId:galleryId type:type albumType:albumType option:option];
        NSDictionary *pathData = [PMConvertUtils convertPathToMap:array];

        [handler reply:@{@"list": pathData}];
    } else if ([@"copyAsset" isEqualToString:call.method]) {
        NSString *assetId = call.arguments[@"assetId"];
        NSString *galleryId = call.arguments[@"galleryId"];
        [manager copyAssetWithId:assetId toGallery:galleryId block:^(PMAssetEntity *entity, NSString *msg) {
          if (msg) {
              NSLog(@"copy asset error, cause by : %@", msg);
              [handler reply:nil];
          } else {
              [handler reply:[PMConvertUtils convertPMAssetToMap:entity needTitle:NO]];
          }
        }];
    } else if ([@"createFolder" isEqualToString:call.method]) {
        [self createFolder:call manager:manager handler:handler];
    } else if ([@"createAlbum" isEqualToString:call.method]) {
        [self createAlbum:call manager:manager handler:handler];
    } else if ([@"removeInAlbum" isEqualToString:call.method]) {
        NSArray *assetId = call.arguments[@"assetId"];
        NSString *pathId = call.arguments[@"pathId"];

        [manager removeInAlbumWithAssetId:assetId albumId:pathId block:^(NSString *msg) {
          if (msg) {
              [handler reply:@{@"msg": msg}];
          } else {
              [handler reply:@{@"success": @YES}];
          }
        }];
    } else if ([@"getAssetCount" isEqualToString:call.method]) {
        int type = [call.arguments[@"type"] intValue];
        NSObject <PMBaseFilter> *option =
        [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        NSUInteger count = [manager getAssetCountWithType:type option:option];
        [handler reply:@(count)];
    } else if ([@"getAssetsByRange" isEqualToString:call.method]) {
        int type = [call.arguments[@"type"] intValue];
        int start = [call.arguments[@"start"] intValue];
        int end = [call.arguments[@"end"] intValue];
        NSObject <PMBaseFilter> *option =
        [PMConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        NSArray<PMAssetEntity*> *array= [manager getAssetsWithType:type option: option start:start end:end];
        NSDictionary *resultDict = [PMConvertUtils convertAssetToMap:array optionGroup:option];
        [handler reply:resultDict];
    } else if ([@"deleteAlbum" isEqualToString:call.method]) {
        NSString *id = call.arguments[@"id"];
        int type = [call.arguments[@"type"] intValue];
        [manager removeCollectionWithId:id type:type block:^(NSString *msg) {
          if (msg) {
              [handler reply:@{@"errorMsg": msg}];
          } else {
              [handler reply:@{@"result": @YES}];
          }
        }];
    } else if ([@"favoriteAsset" isEqualToString:call.method]) {
        NSString *id = call.arguments[@"id"];
        BOOL favorite = [call.arguments[@"favorite"] boolValue];
        BOOL favoriteResult = [manager favoriteWithId:id favorite:favorite];
        [handler reply:@(favoriteResult)];
    } else if ([@"requestCacheAssetsThumb" isEqualToString:call.method]) {
        NSArray *ids = call.arguments[@"ids"];
        PMThumbLoadOption *option = [PMThumbLoadOption optionDict:call.arguments[@"option"]];
        [manager requestCacheAssetsThumb:ids option:option];
        [handler reply:@YES];
    } else if ([@"cancelCacheRequests" isEqualToString:call.method]) {
        [manager cancelCacheRequests];
        [handler reply:@YES];
    } else {
        [handler notImplemented];
    }
}

- (NSDictionary *)convertToResult:(NSString *)id errorMsg:(NSString *)errorMsg {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
    if (errorMsg) {
        mutableDictionary[@"errorMsg"] = errorMsg;
    }

    if (id) {
        mutableDictionary[@"id"] = id;
    }

    return mutableDictionary;
}

- (PMProgressHandler *)getProgressHandlerFromDict:(NSDictionary *)dict {
    id progressIndex = dict[@"progressHandler"];
    if (!progressIndex) {
        return nil;
    }
    int index = [progressIndex intValue];
    PMProgressHandler *handler = [PMProgressHandler new];
    [handler register:privateRegistrar channelIndex:index];

    return handler;
}

- (void)createFolder:(FlutterMethodCall *)call manager:(PMManager *)manager handler:(ResultHandler *)handler {
    NSString *name = call.arguments[@"name"];
    BOOL isRoot = [call.arguments[@"isRoot"] boolValue];
    NSString *parentId = call.arguments[@"folderId"];

    if (isRoot) {
        parentId = nil;
    }

    [manager createFolderWithName:name parentId:parentId block:^(NSString *id, NSString *errorMsg) {
      [handler reply:[self convertToResult:id errorMsg:errorMsg]];
    }];
}

- (void)createAlbum:(FlutterMethodCall *)call manager:(PMManager *)manager handler:(ResultHandler *)handler {
    NSString *name = call.arguments[@"name"];
    BOOL isRoot = [call.arguments[@"isRoot"] boolValue];
    NSString *parentId = call.arguments[@"folderId"];

    if (isRoot) {
        parentId = nil;
    }

    [manager createAlbumWithName:name parentId:parentId block:^(NSString *id, NSString *errorMsg) {
      [handler reply:[self convertToResult:id errorMsg:errorMsg]];
    }];
}

@end
