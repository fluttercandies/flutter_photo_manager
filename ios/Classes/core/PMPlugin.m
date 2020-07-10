//
// Created by Caijinglong on 2019-09-06.
//

#import "PMPlugin.h"
#import "ConvertUtils.h"
#import "PMAssetPathEntity.h"
#import "PMFilterOption.h"
#import "PMLogUtils.h"
#import "PMManager.h"
#import "PMNotificationManager.h"
#import "ResultHandler.h"
#import "PMResourceUtils.h"

@implementation PMPlugin {
}

- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar {
  [self initNotificationManager:registrar];

  FlutterMethodChannel *channel =
          [FlutterMethodChannel methodChannelWithName:@"top.kikt/photo_manager"
                                      binaryMessenger:[registrar messenger]];
  [self setManager:[PMManager new]];
  [channel
          setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
              [self onMethodCall:call result:result];
          }];
}

- (void)initNotificationManager:(NSObject <FlutterPluginRegistrar> *)registrar {
  self.notificationManager = [PMNotificationManager managerWithRegistrar:registrar];
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
  } else if ([call.method isEqualToString:@"openSetting"]) {
    [PMManager openSetting];
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

- (void)runInBackground:(dispatch_block_t)block {
  dispatch_async(dispatch_get_global_queue(0, 0), block);
}

- (void)onAuth:(FlutterMethodCall *)call result:(FlutterResult)result {
  ResultHandler *handler = [ResultHandler handlerWithResult:result];
  PMManager *manager = self.manager;
  __block PMNotificationManager *notificationManager = self.notificationManager;

  [self runInBackground:^{
      if ([call.method isEqualToString:@"getGalleryList"]) {

        int type = [call.arguments[@"type"] intValue];
        BOOL hasAll = [call.arguments[@"hasAll"] boolValue];
        BOOL onlyAll = [call.arguments[@"onlyAll"] boolValue];
        PMFilterOptionGroup *option =
                [ConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        NSArray<PMAssetPathEntity *> *array = [manager getGalleryList:type hasAll:hasAll onlyAll:onlyAll option:option];
        NSDictionary *dictionary = [ConvertUtils convertPathToMap:array];
        [handler reply:dictionary];


      } else if ([call.method isEqualToString:@"getAssetWithGalleryId"]) {
        NSString *id = call.arguments[@"id"];
        int type = [call.arguments[@"type"] intValue];
        NSUInteger page = [call.arguments[@"page"] unsignedIntValue];
        NSUInteger pageCount = [call.arguments[@"pageCount"] unsignedIntValue];
        PMFilterOptionGroup *option =
                [ConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        NSArray<PMAssetEntity *> *array =
                [manager getAssetEntityListWithGalleryId:id type:type page:page pageCount:pageCount filterOption:option];
        NSDictionary *dictionary =
                [ConvertUtils convertAssetToMap:array optionGroup:option];
        [handler reply:dictionary];

      } else if ([call.method isEqualToString:@"getAssetListWithRange"]) {
        NSString *galleryId = call.arguments[@"galleryId"];
        NSUInteger type = [call.arguments[@"type"] unsignedIntegerValue];
        NSUInteger start = [call.arguments[@"start"] unsignedIntegerValue];
        NSUInteger end = [call.arguments[@"end"] unsignedIntegerValue];
        PMFilterOptionGroup *option =
                [ConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        NSArray<PMAssetEntity *> *array =
                [manager getAssetEntityListWithRange:galleryId type:type start:start end:end filterOption:option];
        NSDictionary *dictionary =
                [ConvertUtils convertAssetToMap:array optionGroup:option];
        [handler reply:dictionary];

      } else if ([call.method isEqualToString:@"getThumb"]) {
        NSString *id = call.arguments[@"id"];
        NSUInteger width = [call.arguments[@"width"] unsignedIntegerValue];
        NSUInteger height = [call.arguments[@"height"] unsignedIntegerValue];
        NSUInteger format = [call.arguments[@"format"] unsignedIntegerValue];
        NSUInteger quality = [call.arguments[@"quality"] unsignedIntegerValue];
        NSNumber * deliveryMode = call.arguments[@"deliveryMode"];
        NSNumber * resizeMode = call.arguments[@"resizeMode"];
        NSNumber * contentMode = call.arguments[@"contentMode"];

        [manager getThumbWithId:id width:width height:height format:format quality:quality deliveryMode: deliveryMode resizeMode: resizeMode contentMode: contentMode resultHandler:handler];

      } else if ([call.method isEqualToString:@"getFullFile"]) {
        NSString *id = call.arguments[@"id"];
        BOOL isOrigin = [call.arguments[@"isOrigin"] boolValue];

        [manager getFullSizeFileWithId:id isOrigin:isOrigin resultHandler:handler];

      } else if ([call.method isEqualToString:@"releaseMemCache"]) {
        [manager clearCache];

      } else if ([call.method isEqualToString:@"log"]) {
        PMLogUtils.sharedInstance.isLog = (BOOL) call.arguments;

      } else if ([call.method isEqualToString:@"fetchPathProperties"]) {
        NSString *id = call.arguments[@"id"];
        int requestType = [call.arguments[@"type"] intValue];
        PMFilterOptionGroup *option =
                [ConvertUtils convertMapToOptionContainer:call.arguments[@"option"]];
        PMAssetPathEntity *pathEntity = [manager fetchPathProperties:id type:requestType filterOption:option];
        if (pathEntity) {
          NSDictionary *dictionary =
                  [ConvertUtils convertPathToMap:@[pathEntity]];
          [handler reply:dictionary];
        } else {
          [handler reply:nil];
        }

      } else if ([call.method isEqualToString:@"openSetting"]) {
        [PMManager openSetting];
      } else if ([call.method isEqualToString:@"notify"]) {
        BOOL notify = [call.arguments[@"notify"] boolValue];
        if (notify) {
          [notificationManager startNotify];
        } else {
          [notificationManager stopNotify];
        }

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
                         NSDictionary *resultData =
                                 [ConvertUtils convertPMAssetToMap:asset needTitle:NO];
                         [handler reply:@{@"data": resultData}];
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
                                 NSDictionary *resultData =
                                         [ConvertUtils convertPMAssetToMap:asset needTitle:NO];
                                 [handler reply:@{@"data": resultData}];
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
                         NSDictionary *resultData =
                                 [ConvertUtils convertPMAssetToMap:asset needTitle:NO];
                         [handler reply:@{@"data": resultData}];
                     }];

      } else if ([call.method isEqualToString:@"assetExists"]) {
        NSString *assetId = call.arguments[@"id"];
        BOOL exists = [manager existsWithId:assetId];
        [handler reply:@(exists)];
      } else if ([call.method isEqualToString:@"getTitleAsync"]) {
        NSString *assetId = call.arguments[@"id"];
        NSString *title = [manager getTitleAsyncWithAssetId:assetId];
        [handler reply:title];
      } else if ([@"getMediaUrl" isEqualToString:call.method]) {
        [manager getMediaUrl:call.arguments[@"id"] resultHandler:handler];
      } else if ([@"getPropertiesFromAssetEntity" isEqualToString:call.method]) {
        NSString *assetId = call.arguments[@"id"];
        PMAssetEntity *entity = [manager getAssetEntity:assetId];
        if (entity == nil) {
          [handler reply:nil];
          return;
        }
        NSDictionary *resultMap = [ConvertUtils convertPMAssetToMap:entity needTitle:YES];
        [handler reply:@{@"data": resultMap}];
      } else if ([@"getSubPath" isEqualToString:call.method]) {
        NSString *galleryId = call.arguments[@"id"];
        int type = [call.arguments[@"type"] intValue];
        int albumType = [call.arguments[@"albumType"] intValue];
        NSDictionary *optionMap = call.arguments[@"option"];
        PMFilterOptionGroup *option = [ConvertUtils convertMapToOptionContainer:optionMap];

        NSArray<PMAssetPathEntity *> *array = [manager getSubPathWithId:galleryId type:type albumType:albumType option:option];
        NSDictionary *pathData = [ConvertUtils convertPathToMap:array];

        [handler reply:@{@"list": pathData}];
      } else if ([@"copyAsset" isEqualToString:call.method]) {
        NSString *assetId = call.arguments[@"assetId"];
        NSString *galleryId = call.arguments[@"galleryId"];
        [manager copyAssetWithId:assetId toGallery:galleryId block:^(PMAssetEntity *entity, NSString *msg) {
            if (msg) {
              NSLog(@"copy asset error, cause by : %@", msg);
              [handler reply:nil];
            } else {
              [handler reply:[ConvertUtils convertPMAssetToMap:entity needTitle:NO]];
            }
        }];

      } else if ([@"createFolder" isEqualToString:call.method]) {
        NSString *name = call.arguments[@"name"];
        BOOL isRoot = [call.arguments[@"isRoot"] boolValue];
        NSString *parentId = call.arguments[@"folderId"];

        if (isRoot) {
          parentId = nil;
        }

        [manager createFolderWithName:name parentId:parentId block:^(NSString *id, NSString *errorMsg) {
            [handler reply:[self convertToResult:@{@"id": id, @"errorMsg": errorMsg}]];
        }];

      } else if ([@"createAlbum" isEqualToString:call.method]) {
        NSString *name = call.arguments[@"name"];
        BOOL isRoot = [call.arguments[@"isRoot"] boolValue];
        NSString *parentId = call.arguments[@"folderId"];

        if (isRoot) {
          parentId = nil;
        }

        [manager createAlbumWithName:name parentId:parentId block:^(NSString *id, NSString *errorMsg) {
            NSDictionary *dictionary = @{@"id": id, @"errorMsg": errorMsg};
            [handler reply:[self convertToResult:dictionary]];
        }];

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
        BOOL favorite = [call.arguments[@"type"] boolValue];
        BOOL favoriteResult = [manager favoriteWithId:id favorite:favorite];

        [handler reply:@(favoriteResult)];
      } else if ([@"getFileSize" isEqualToString:call.method]) {
        NSString *id = call.arguments[@"id"];
        
        PMAssetEntity *assetEntity = [manager getAssetEntity:id];
          
        PMResourceUtils *utils = [PMResourceUtils new];
        NSNumber *fileSize = [utils getPHAssetSize:assetEntity.phAsset];
        [handler reply:fileSize];
      } else {
        [handler notImplemented];
      }
  }];

}

- (NSDictionary *)convertToResult:(NSDictionary *)dict {
  NSMutableDictionary *result = [NSMutableDictionary new];

  for (id key in dict.allKeys) {
    id value = dict[key];
    if (value) {
      result[key] = value;
    }
  }

  return result;
}

@end
