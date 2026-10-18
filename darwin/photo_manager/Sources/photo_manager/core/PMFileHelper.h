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
/// Make an asset title safe to use as the decorative part of an export cache
/// filename. `/` and `:` become `_`. A title longer than 40 UTF-16 code units is
/// cut where the composed character sequence that crosses that budget starts,
/// so no sequence is split and the result never exceeds the budget; when the
/// first sequence alone is longer, the result is empty. Shorter titles are
/// returned unchanged. See #1445.
+ (nullable NSString *)cacheFilenameTitleForTitle:(nullable NSString *)title;

@end

NS_ASSUME_NONNULL_END
