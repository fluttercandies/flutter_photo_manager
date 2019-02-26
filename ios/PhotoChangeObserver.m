//
// Created by Caijinglong on 2019-02-26.
//

#import <Photos/Photos.h>
#import "PhotoChangeObserver.h"

@interface PhotoChangeObserver () <PHPhotoLibraryChangeObserver>
@property(nonatomic, strong) FlutterMethodChannel *handler;
@property(nonatomic, assign) BOOL isInit;
@end

@implementation PhotoChangeObserver {


}

- (void)initWithRegister:(NSObject <FlutterPluginRegistrar> *)registrar {
    if (self.isInit) {
        return;
    }
    self.isInit = YES;
    self.handler = [FlutterMethodChannel methodChannelWithName:@"photo_manager/notify" binaryMessenger:[registrar messenger]];
    [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
//    NSLog(@"photo library is change");
    [self.handler invokeMethod:@"change" arguments:@1];
}


@end