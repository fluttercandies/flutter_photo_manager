#import "ImageScannerPlugin.h"
#import "Reply.h"
#import "PhotoChangeObserver.h"

@implementation ImageScannerPlugin {
}
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"image_scanner"
                  binaryMessenger:[registrar messenger]];
    ImageScannerPlugin *instance = [[ImageScannerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];

    instance.scanner = [[ImageScanner alloc] init];
    instance.scanner.registrar = registrar;

    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSLog(@"application path = %@", path);
    
    instance.registrar = registrar;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"openSetting" isEqualToString:call.method]) {
        [ImageScanner openSetting];
        result(@"");
        return;
    }

    if ([@"requestPermission" isEqualToString:call.method]) {
        [_scanner requestPermissionWithResult:result];
    } else if ([@"getGalleryIdList" isEqualToString:call.method]) {
        [_scanner getGalleryIdList:call result:result];
    } else if ([@"getGalleryNameList" isEqualToString:call.method]) {
        [_scanner getGalleryNameWithCall:call result:result];
    } else if ([@"getImageListWithPathId" isEqualToString:call.method]) {
        [_scanner getImageListWithCall:call result:result];
    } else if ([@"getAllImageList" isEqualToString:call.method]) {
        [_scanner forEachAssetCollection:call result:result];
    } else if ([@"getThumbPath" isEqualToString:call.method]) {
        [_scanner getThumbPathWithCall:call result:result];
    } else if ([@"getThumbBytesWithId" isEqualToString:call.method]) {
        [_scanner getThumbBytesWithCall:call result:result reply:[Reply replyWithIsReply:NO]];
    } else if ([@"getFullFileWithId" isEqualToString:call.method]) {
        [_scanner getFullFileWithCall:call result:result reply:[Reply replyWithIsReply:NO]];
    } else if ([@"getBytesWithId" isEqualToString:call.method]) {
        [_scanner getBytesWithCall:call result:result reply:[Reply replyWithIsReply:NO]];
    } else if ([@"getAssetTypeWithIds" isEqualToString:call.method]) {
        [_scanner getAssetTypeByIdsWithCall:call result:result];
    } else if([@"isCloudWithImageId" isEqualToString:call.method]){
        [_scanner isCloudWithCall:call result:result];
    } else if([@"getDurationWithId" isEqualToString:call.method]){
        [_scanner getDurationWithId:call result:result];
    } else if([@"getSizeWithId" isEqualToString:call.method]){
        [_scanner getSizeWithId:call result:result];
    } else if([@"releaseMemCache" isEqualToString:call.method]){
        [_scanner releaseMemCache:call result:result];
    } else if ([@"getVideoPathList" isEqualToString:call.method]) {
        [_scanner getVideoPathList:call result:result];
    } else if ([@"getImagePathList" isEqualToString:call.method]) {
        [_scanner getImagePathList:call result:result];
    } else if ([@"getAllVideo" isEqualToString:call.method]) {
        [_scanner getAllVideo:call result:result];
    } else if ([@"getOnlyVideoWithPathId" isEqualToString:call.method]) {
        [_scanner getOnlyVideoWithPathId:call result:result];
    } else if ([@"getAllImage" isEqualToString:call.method]) {
        [_scanner getAllImage:call result:result];
    } else if ([@"getOnlyImageWithPathId" isEqualToString:call.method]) {
        [_scanner getOnlyImageWithPathId:call result:result];
    } else if ([@"createAssetWithId" isEqualToString:call.method]) {
        [_scanner createAssetWithIdWithCall:call result:result];
    } else if ([@"getTimeStampWithIds" isEqualToString:call.method]) {
        [_scanner getTimeStampWithIdsWithCall:call result:result];
    }else if ([@"assetExistsWithId" isEqualToString:call.method]) {
        [_scanner assetExistsWithId:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
