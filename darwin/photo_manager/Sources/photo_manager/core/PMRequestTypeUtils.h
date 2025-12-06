#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface PMRequestTypeUtils : NSObject

+ (BOOL)containsImage:(int)type;

+ (BOOL)containsVideo:(int)type;

+ (BOOL)containsAudio:(int)type;

+ (PHFetchOptions *)getFetchOptionsByType:(int)type;

@end
