#import "PhotoManagerPlugin.h"
#import "PMPlugin.h"

@implementation PhotoManagerPlugin {
}

@synthesize plugin;
@synthesize registrar;

+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    PhotoManagerPlugin* photoManagerPlugin = [[PhotoManagerPlugin alloc] init];
    photoManagerPlugin.plugin =  [[PMPlugin alloc] init];
    photoManagerPlugin.registrar = registrar;
    
    [photoManagerPlugin.plugin registerPlugin:registrar];
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    [plugin detachFromEngine];
}

@end
