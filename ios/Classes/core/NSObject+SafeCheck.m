#import "NSObject+SafeCheck.h"

@implementation NSObject (SafeCheck)

- (BOOL)isNilOrNull {
    return NO;
}

@end


@implementation NSNull (SafeCheck)

- (BOOL)isNilOrNull {
    return YES;
}

@end
