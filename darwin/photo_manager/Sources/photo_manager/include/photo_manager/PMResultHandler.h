#import "PMImport.h"
#import <Foundation/Foundation.h>

@interface PMResultHandler : NSObject

@property(nonatomic, strong) FlutterMethodCall* call;
@property(nonatomic, strong) FlutterResult result;

- (instancetype)initWithResult:(FlutterResult)result;

- (instancetype)initWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

+ (instancetype)handlerWithCall:(FlutterMethodCall *)call result:(FlutterResult)result;

- (void)replyError:(NSObject *)value;

- (void)reply:(id)obj;

- (void)notImplemented;

- (BOOL)isReplied;

- (NSString *)getCancelToken;

@end
