//
// Created by jinglong cai on 2020/7/18.
//

#import "PMResourceManager.h"
#import <Flutter/Flutter.h>

@implementation PMResourceManager {
    FlutterMethodChannel *channel;
    BOOL running;
    PHAssetResourceDataRequestID requestId;
}
- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar asset:(PHAsset *)asset {
    self = [super init];
    if (self) {
        self.registrar = registrar;
        self.asset = asset;
        running = NO;
    }

    return self;
}

+ (instancetype)managerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar asset:(PHAsset *)asset {
    return [[self alloc] initWithRegistrar:registrar asset:asset];
}


- (PHAssetResource *)findLastResource {
    NSArray<PHAssetResource *> *array = [PHAssetResource assetResourcesForAsset:self.asset];
    for (NSUInteger i = array.count - 1; i >= 0; --i) {
        PHAssetResource *resource = array[i];
        if (self.asset.mediaType == PHAssetMediaTypeImage) {
            if (resource.type == PHAssetResourceTypePhoto || resource.type == PHAssetResourceTypeFullSizePhoto) {
                return resource;
            }
        } else if (self.asset.mediaType == PHAssetMediaTypeVideo) {
            if (resource.type == PHAssetResourceTypeVideo || resource.type == PHAssetResourceTypeFullSizeVideo) {
                return resource;
            }
        }
    }

    return nil;
}

- (NSString *)getChannelName {
    return [NSString stringWithFormat:@"top.kikt/photo_manager/stream/%@", self.asset.localIdentifier];
}

- (void)handleMethodResult:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"start"]) {
        [self start];
        result(@YES);
    } else if ([call.method isEqualToString:@"stop"]) {
        [self stop];
        result(@YES);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (NSDictionary *)toDict {
    NSString *channelName = [self getChannelName];
    if (!channel) {
        channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:self.registrar.messenger];
        [channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            [self handleMethodResult:call result:result];
        }];
    }
    return @{@"channelName": channelName, @"running": @(running)};
}

- (void)start {
    if (running) {
        return;
    }
    running = YES;
    PHAssetResource *resource = [self findLastResource];
    requestId = [[PHAssetResourceManager defaultManager] requestDataForAssetResource:resource options:nil dataReceivedHandler:^(NSData *data) {
        FlutterStandardTypedData *d = [FlutterStandardTypedData typedDataWithBytes:data];
        [channel invokeMethod:@"onReceived" arguments:@{@"data": d}];
    }                                                              completionHandler:^(NSError *error) {
        running = NO;
        if (error) {
            [channel invokeMethod:@"happen error" arguments:@{@"error": error.localizedDescription}];
        } else {
            [channel invokeMethod:@"completion" arguments:@{}];
        }
    }];
}

- (void)stop {
    if (running && requestId) {
        running = NO;
        [[PHAssetResourceManager defaultManager] cancelDataRequest:requestId];
    }

}

- (void)onRelease {
    [self stop];
    [channel setMethodCallHandler:nil];
}

@end