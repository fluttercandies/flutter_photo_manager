#import "PMImport.h"
#import "PMPlugin.h"

@interface PhotoManagerPlugin : NSObject <FlutterPlugin>
@property(nonatomic, strong) PMPlugin* plugin;
@property(nonatomic, strong) NSObject <FlutterPluginRegistrar> *registrar;
@end
