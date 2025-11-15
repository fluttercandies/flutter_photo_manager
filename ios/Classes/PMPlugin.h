#import "PMImport.h"
#import "PMResultHandler.h"
#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>

@class PMManager;
@class PMNotificationManager;

@interface PMPlugin : NSObject<FlutterPlugin, PHPickerViewControllerDelegate>
@property(nonatomic, strong) PMManager *manager;
@property(nonatomic, strong) PMNotificationManager *notificationManager;
- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar;

@property(nonatomic, strong) PMResultHandler *pickerResultHandler;

@end
