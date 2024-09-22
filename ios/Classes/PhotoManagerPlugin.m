#import "PhotoManagerPlugin.h"
#import "PMPlugin.h"

@implementation PhotoManagerPlugin {
}
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    PMPlugin *plugin = [PMPlugin new];
    [plugin registerPlugin:registrar];
    [registrar addApplicationDelegate:plugin];
}

@end
