#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "PMImport.h"

@protocol FlutterPluginRegistrar;

@interface PMNotificationManager : NSObject
@property(nonatomic, strong) NSObject <FlutterPluginRegistrar> *registrar;

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar;

- (void)startNotify;

- (void)stopNotify;

- (void)photoLibraryDidChange:(PHChange *)changeInstance;

+ (instancetype)managerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar;

- (BOOL)isNotifying;

- (void)detach;

@end
