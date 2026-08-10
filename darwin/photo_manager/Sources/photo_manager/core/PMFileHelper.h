//
//  PMFileHelper.h
//  photo_manager
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///  Contains access file methods
@interface PMFileHelper : NSObject

+(void)deleteFile:(NSString *)path isDirectory:(BOOL)isDirectory error:(NSError *)error;
/// Atomically move a file into its final cache path. Any existing destination
/// is removed first. On failure the source is deleted so no partial file is
/// left behind for a later existence-only cache check to serve. See #1432.
+ (BOOL)moveItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
