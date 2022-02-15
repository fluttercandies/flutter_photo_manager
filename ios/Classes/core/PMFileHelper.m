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

@end
