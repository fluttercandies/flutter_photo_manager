#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#define PMFileHashDefaultChunkSizeForReadingData 1024*8 // 8K

@interface PMMD5Utils : NSObject

// 计算 NSData 的 MD5
+ (NSString *)getMD5FromData:(NSData *)data;

// 计算字符串的 MD5
+ (NSString *)getMD5FromString:(NSString *)string;

// 计算文件的 MD5
+ (NSString *)getMD5FromPath:(NSString *)path;

@end
