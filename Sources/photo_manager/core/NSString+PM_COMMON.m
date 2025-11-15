#import "NSString+PM_COMMON.h"

@implementation NSString (PM_COMMON)

- (BOOL)isEmpty {
    if (self.length == 0) {
        return YES;
    }
    if ([self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        return YES;
    }
    return NO;
}

@end
