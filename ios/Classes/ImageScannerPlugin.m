#import "ImageScannerPlugin.h"
#import "Reply.h"

@implementation ImageScannerPlugin {
}
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"image_scanner"
                  binaryMessenger:[registrar messenger]];
    ImageScannerPlugin *instance = [[ImageScannerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];

    instance.scanner = [[ImageScanner alloc] init];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSLog(@"沙盒目录 = %@",path);
    
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
        [_scanner getAllImageListWithCall:call result:result];
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
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
