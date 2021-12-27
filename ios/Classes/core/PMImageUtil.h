//
//  PMImageUtil.h
//  path_provider_macos
//

#import <Foundation/Foundation.h>
#import "PMThumbLoadOption.h"

#if TARGET_OS_IOS
typedef UIImage PMImage;
#endif

#if TARGET_OS_OSX
typedef NSImage PMImage;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PMImageUtil : NSObject

+ (NSData *)convertToData:(PMImage *)image formatType:(PMThumbFormatType)type quality:(float)quality;

@end

NS_ASSUME_NONNULL_END
