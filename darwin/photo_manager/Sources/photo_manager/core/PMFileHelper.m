//
//  PMFileHelper.m
//  photo_manager
//

#import "PMFileHelper.h"

// The title is decorative in an export cache filename: the asset identifier and
// the modification date already identify the asset and its current version, so
// sanitising or shortening the title cannot cause collisions.
//
// It has to be bounded, because it is not under the app's control. Assets
// imported from social apps carry their whole caption as the title, and a name
// component longer than 255 characters makes copying the asset into the cache
// fail with NSFileWriteInvalidFileNameError (514). The file system receives the
// canonically decomposed form of the name, and decomposition turns a UTF-16
// code unit into at most four (UAX #15), so a title of 40 code units takes at
// most 160 characters next to the identifier and timestamp prefix (about 64
// characters) and the extension.
static const NSUInteger PMMaxCacheFilenameTitleLength = 40;

@implementation PMFileHelper

+ (void)deleteFile:(NSString *)path isDirectory:(BOOL)isDirectory error:(NSError *)error {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    if (exists) {
        [fileManager removeItemAtPath:path error:&error];
    }
}

+ (BOOL)moveItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError * _Nullable *)error {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    [fileManager removeItemAtPath:destinationPath error:nil];
    if (![fileManager moveItemAtPath:sourcePath toPath:destinationPath error:error]) {
        [fileManager removeItemAtPath:sourcePath error:nil];
        return NO;
    }
    return YES;
}

+ (NSString *)cacheFilenameTitleForTitle:(NSString *)title {
    // A separator inside a title would escape the cache directory.
    NSString *result = [title stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    result = [result stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    if (result.length <= PMMaxCacheFilenameTitleLength) {
        return result;
    }
    // Keep only the sequences that end within the budget. The sequence that
    // contains the first code unit past the budget starts at or before it, so
    // its location is the cut: 0 when the first sequence alone is too long.
    // (`rangeOfComposedCharacterSequencesForRange:` would expand the range to
    // the end of that sequence instead, keeping an unbounded title.)
    NSRange crossing = [result rangeOfComposedCharacterSequenceAtIndex:PMMaxCacheFilenameTitleLength];
    return [result substringToIndex:crossing.location];
}

@end
