#import <Foundation/Foundation.h>

@interface PMLogUtils : NSObject

@property(nonatomic, assign) BOOL isLog;

+ (instancetype)sharedInstance;

- (void)info:(NSString *)info;
- (void)debug:(NSString *)info;

@end