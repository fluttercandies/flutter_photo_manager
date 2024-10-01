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

    if (!channel) {
        return;
    }
    
    // Use the main thread to invoke the method.
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            FlutterMethodChannel *channel = self->channel;
            if (!channel) {
                return;
            }
            // Try to invoke the channel in the thread, regardless if it's available.
            [channel invokeMethod:@"notifyProgress" arguments:dict];
        } @catch (NSException *exception) {
            // Do nothing when it throws.
        } @finally {
            if (state == PMProgressStateSuccess || state == PMProgressStateFailed) {
                [self->channel setMethodCallHandler:nil];
                self->channel = nil;
            }
        }
    });
}

- (void)register:(NSObject <FlutterPluginRegistrar> *)registrar channelIndex:(int)index {
    NSString *name = [NSString stringWithFormat:@"com.fluttercandies/photo_manager/progress/%d", index];
    channel = [FlutterMethodChannel methodChannelWithName:name binaryMessenger:registrar.messenger];
}

@end
