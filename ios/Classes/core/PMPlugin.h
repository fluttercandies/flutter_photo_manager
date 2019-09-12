//
// Created by Caijinglong on 2019-09-06.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@class PMManager;

@interface PMPlugin : NSObject
@property(nonatomic, strong) PMManager *manager;

- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar;

@end