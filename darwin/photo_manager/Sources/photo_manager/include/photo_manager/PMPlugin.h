#import "PMImport.h"
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@class PMManager;
@class PMNotificationManager;
@class PMResultHandler;

#if TARGET_OS_IOS
@interface PMPlugin : NSObject<FlutterPlugin, PHPickerViewControllerDelegate>
#else
@interface PMPlugin : NSObject<FlutterPlugin>
#endif

@property(nonatomic, strong) PMManager *manager;
@property(nonatomic, strong) PMNotificationManager *notificationManager;
@property(nonatomic, strong) PMResultHandler *pickerResultHandler;
@property(nonatomic, assign) BOOL pickerUseItemProvider;
- (void)registerPlugin:(NSObject <FlutterPluginRegistrar> *)registrar;

@end
