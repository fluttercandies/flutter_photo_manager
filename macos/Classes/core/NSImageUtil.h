//
//  NSImageUtil.h
//  path_provider_macos
//
//  Created by jinglong cai on 2021/4/12.
//

#import <Foundation/Foundation.h>
#import "PMThumbLoadOption.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSImageUtil : NSObject

+ (NSData *)convertToData:(NSImage *)image formatType:(PMThumbFormatType)type quality:(float)quality;

@end

NS_ASSUME_NONNULL_END
