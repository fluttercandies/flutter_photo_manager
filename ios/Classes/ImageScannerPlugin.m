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
    if ([@"getImageIdList" isEqualToString:call.method]) {
        [_scanner getImageIdList:call result:result];
    } else if ([@"getImagePathList" isEqualToString:call.method]) {

    } else if ([@"getImageListWithPathId" isEqualToString:call.method]) {

    } else if ([@"getImageThumbListWithPathId" isEqualToString:call.method]) {

    } else if ([@"getThumbPath" isEqualToString:call.method]) {

    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
