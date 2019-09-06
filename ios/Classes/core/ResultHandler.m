//
// Created by Caijinglong on 2019-09-06.
//

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

+ (instancetype)handlerWithResult:(FlutterResult)result {
    return [[self alloc] initWithResult:result];
}

- (void)reply:(id)obj {
    if (isReply) {
        return;
    }
    isReply = YES;

    self.result(obj);
}

- (void)replyError:(NSString *)errorCode {
    if (isReply) {
        return;
    }
    isReply = YES;
    FlutterError *error = [FlutterError errorWithCode:errorCode message:nil details:nil];
    self.result(error);
}

- (BOOL)isReplied {
    return isReply;
}
@end