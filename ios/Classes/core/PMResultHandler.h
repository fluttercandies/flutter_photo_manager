#import <Foundation/Foundation.h>

@protocol PMResultHandler <NSObject>

- (void)replyError:(NSObject *)value;

- (void)reply:(id)obj;

- (void)notImplemented;

- (BOOL)isReplied;

@end
