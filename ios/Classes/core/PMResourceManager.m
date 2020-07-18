//
// Created by jinglong cai on 2020/7/18.
//

#import "PMResourceManager.h"
#import <Flutter/Flutter.h>

@implementation PMResourceManager {
    FlutterMethodChannel *channel;
    BOOL running;
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

- (NSDictionary *)toDict {
    NSString *channelName = [self getChannelName];
    channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:self.registrar.messenger];
    return @{@"channelName": channelName, @"running": @(running)};
}

- (void)start {
    running = YES;
    PHAssetResource *resource = [self findLastResource];
    [[PHAssetResourceManager defaultManager] requestDataForAssetResource:resource options:nil dataReceivedHandler:^(NSData *data) {
        FlutterStandardTypedData *d = [FlutterStandardTypedData typedDataWithBytes:data];
        [channel invokeMethod:@"onReceived" arguments:@{@"data": d}];
    }                                                  completionHandler:^(NSError *error) {
        if (error) {
            [channel invokeMethod:@"happen error" arguments:@{@"error": error.localizedDescription}];
        } else {
            [channel invokeMethod:@"completion" arguments:@{}];
        }
    }];
}

@end