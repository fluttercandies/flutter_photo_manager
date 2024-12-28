#import "ResultHandler.h"

@implementation ResultHandler {
    BOOL isReply;
}
- (instancetype)initWithResult:(FlutterResult)result {
    self = [super init];
    if (self) {
        self.result = result;
        isReply = NO;
    }
    
    return self;
}

- (instancetype)initWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    self = [super init];
    if (self) {
        self.call = call;
        self.result = result;
    }

    return self;
}

+ (instancetype)handlerWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    return [[self alloc] initWithCall:call result:result];
}


- (void)reply:(id)obj {
    if (isReply) {
        return;
    }
    isReply = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.result(obj);
    });
}

- (void)replyError:(NSObject *)value {
    if (isReply) {
        return;
    }
    isReply = YES;
    
    FlutterError *flutterError;
    if ([value isKindOfClass:[NSError class]]) {
        NSError *error = (NSError *)value;
        NSString *code = [NSString stringWithFormat:@"%@ (%ld)", error.domain, (long)error.code];
        NSString *message = error.userInfo[NSLocalizedDescriptionKey] ?: error.localizedDescription ?: @"Unknown error";
        NSString *details = error.userInfo[NSLocalizedFailureReasonErrorKey] ?: error.localizedFailureReason ?: @"No failure reason provided";
        flutterError = [FlutterError errorWithCode:code message:message details:details];
    } else if ([value isKindOfClass:[NSException class]]) {
        NSException *exception = (NSException *)value;
        NSString *code = exception.name ?: @"UnknownException";
        NSString *message = exception.reason ?: @"An unknown exception occurred.";
        NSString *details = exception.callStackSymbols ? [exception.callStackSymbols componentsJoinedByString:@"\n"] : @"No stack trace available.";
        flutterError = [FlutterError errorWithCode:code message:message details:details];
    } else {
        NSString *code = NSStringFromClass([value class]) ?: @"UnknownException";
        NSString *message = [NSString stringWithFormat:@"%@", [value description]];
        flutterError = [FlutterError errorWithCode:code message:message details:nil];
    }
    if ([NSThread isMainThread]) {
        self.result(flutterError);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.result(flutterError);
        });
    }
}

- (void)notImplemented {
    if (isReply) {
        return;
    }
    isReply = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.result(FlutterMethodNotImplemented);
    });
    
}

- (BOOL)isReplied {
    return isReply;
}
@end
