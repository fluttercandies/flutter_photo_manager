#import "PMImport.h"
#import <Foundation/Foundation.h>

@protocol FlutterPluginRegistrar;

@interface PMNotificationManager : NSObject
@property(nonatomic, strong) NSObject <FlutterPluginRegistrar> *registrar;

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar;

- (void)startNotify;

- (void)stopNotify;

+ (instancetype)managerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar;

- (BOOL)isNotifying;

- (void)detach;

@end
