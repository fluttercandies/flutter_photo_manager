#import <Foundation/Foundation.h>
#import "PMImport.h"
#import "PMResultHandler.h"

@interface ResultHandler : NSObject <PMResultHandler>

@property(nonatomic, strong) FlutterResult result;

+ (instancetype)handlerWithResult:(FlutterResult)result;

- (instancetype)initWithResult:(FlutterResult)result;

@end
