//
//  PMFileHelper.m
//  photo_manager
//

#import "PMFileHelper.h"

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

@end
