#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SafeCheck)

/**
 * @brief Checks if the object is either nil or an instance of NSNull.
 * @return YES if the object is nil or [NSNull null], otherwise NO.
 */
- (BOOL)isNilOrNull;

@end

NS_ASSUME_NONNULL_END
