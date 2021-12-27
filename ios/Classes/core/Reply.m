#import "Reply.h"

@implementation Reply {
    
}

- (instancetype)initWithIsReply:(BOOL)isReply {
    self = [super init];
    if (self) {
        self.isReply = isReply;
    }
    
    return self;
}

+ (instancetype)replyWithIsReply:(BOOL)isReply {
    return [[self alloc] initWithIsReply:isReply];
}

@end
