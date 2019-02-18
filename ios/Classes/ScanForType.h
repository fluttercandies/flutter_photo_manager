//
// Created by Caijinglong on 2019-02-18.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@protocol ScanForType <NSObject>

- (void)getVideoPathList:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getAllVideo:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getOnlyVideoWithPathId:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getImagePathList:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getAllImage:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)getOnlyImageWithPathId:(FlutterMethodCall *)call result:(FlutterResult)result;

@end
