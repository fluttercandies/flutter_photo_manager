#import <Foundation/Foundation.h>
#import "PMImport.h"
#import "PMResultHandler.h"

@interface ResultHandler : NSObject <PMResultHandler>

@property (nonatomic, strong) FlutterMethodCall* call;
@property(nonatomic, strong) FlutterResult result;

- (instancetype)initWithResult:(FlutterResult)result;

- (instancetype)initWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

+ (instancetype)handlerWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;


@end
