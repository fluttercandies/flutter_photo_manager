//
// Created by jinglong cai on 2020/7/18.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <Flutter/Flutter.h>

@interface PMResourceManager : NSObject

@property(strong, nonatomic) NSObject <FlutterPluginRegistrar> *registrar;
@property(strong, nonatomic) PHAsset *asset;

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar asset:(PHAsset *)asset;

+ (instancetype)managerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar asset:(PHAsset *)asset;

- (NSDictionary *)toDict;


@end