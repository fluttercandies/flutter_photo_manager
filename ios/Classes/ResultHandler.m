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

- (void)replyError:(NSString *)errorCode {
    if (isReply) {
        return;
    }
    isReply = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        FlutterError *error = [FlutterError errorWithCode:errorCode message:nil details:nil];
        self.result(error);
    });
    
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
