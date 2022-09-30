#import <Foundation/Foundation.h>
#import "PMImport.h"

@interface PhotoChangeObserver : NSObject
- (void)initWithRegister:(NSObject <FlutterPluginRegistrar> *)registrar;
- (void)detachFromEngine;
@end
