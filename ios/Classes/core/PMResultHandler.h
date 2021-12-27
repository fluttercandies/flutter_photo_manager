#import <Foundation/Foundation.h>

@protocol PMResultHandler <NSObject>

- (void)replyError:(NSString *)errorCode;

- (void)reply:(id)obj;

- (void)notImplemented;

- (BOOL)isReplied;

@end