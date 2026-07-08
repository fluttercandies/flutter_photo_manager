#import <Foundation/Foundation.h>

@interface PMHashUtils : NSObject

// Returns a lowercase hex SHA-256 digest of the given string's UTF-8 bytes.
// Used to derive stable cache filenames from PHAsset local identifiers; not for security.
+ (NSString *)sha256FromString:(NSString *)string;

@end
