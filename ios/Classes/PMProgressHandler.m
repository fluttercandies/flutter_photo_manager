//
//  PMProgressHandler.m
//  path_provider
//

#import "PMProgressHandler.h"

@implementation PMProgressHandler {
    FlutterMethodChannel *channel;
}

- (void)notify:(double)progress state:(PMProgressState)state {
    int s = state;
    NSDictionary *dict = @{
        @"state": @(s),
        @"progress": @(progress),
    };

    if (channel) {
        // Use the main thread to invoke the method.
        dispatch_async(dispatch_get_main_queue(), ^{
          [channel invokeMethod:@"notifyProgress" arguments:dict];
        });
    }

}

- (void)register:(NSObject <FlutterPluginRegistrar> *)registrar channelIndex:(int)index {
    NSString *name = [NSString stringWithFormat:@"com.fluttercandies/photo_manager/progress/%d", index];
    channel = [FlutterMethodChannel methodChannelWithName:name binaryMessenger:registrar.messenger];
}

- (void)deinit {
    channel = nil;
}

@end
