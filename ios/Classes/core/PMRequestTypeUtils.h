#import <Foundation/Foundation.h>

@interface PMRequestTypeUtils : NSObject

+ (BOOL)containsImage:(int)type;

+ (BOOL)containsVideo:(int)type;

+ (BOOL)containsAudio:(int)type;

@end
