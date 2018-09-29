#import "ImageScannerPlugin.h"

@implementation ImageScannerPlugin {
}
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"image_scanner"
                  binaryMessenger:[registrar messenger]];
    ImageScannerPlugin *instance = [[ImageScannerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];

    instance.scanner = [[ImageScanner alloc] init];
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
        [_scanner getThumbBytesWithCall:call result:result];
    } else if ([@"getFullFileWithId" isEqualToString:call.method]) {
        [_scanner getFullFileWithCall:call result:result];
    } else if ([@"getBytesWithId" isEqualToString:call.method]) {
        [_scanner getBytesWithCall:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
