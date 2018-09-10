#import <Flutter/Flutter.h>
#import "ImageScanner.h"

@interface ImageScannerPlugin : NSObject <FlutterPlugin>
@property(nonatomic, strong) NSObject <FlutterPluginRegistrar> *registrar;

@property(nonatomic, strong) ImageScanner *scanner;
@end
