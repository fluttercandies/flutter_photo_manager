#import <Foundation/Foundation.h>
#import "PMImport.h"
#import <Photos/Photos.h>

@class PMManager;
@class PMNotificationManager;

@interface PMPlugin : NSObject
@property(nonatomic, strong) PMManager *manager;
@property(nonatomic, strong) PMNotificationManager *notificationManager;
- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar;

@end
