#import "PMImport.h"
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@class PMManager;
@class PMNotificationManager;

@interface PMPlugin : NSObject<FlutterPlugin>
@property(nonatomic, strong) PMManager *manager;
@property(nonatomic, strong) PMNotificationManager *notificationManager;
- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar;

@end
