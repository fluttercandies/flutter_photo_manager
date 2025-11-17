#import <Foundation/Foundation.h>

@interface Reply : NSObject

@property (nonatomic, assign) BOOL isReply;

- (instancetype)initWithIsReply:(BOOL)isReply;

+ (instancetype)replyWithIsReply:(BOOL)isReply;


@end
