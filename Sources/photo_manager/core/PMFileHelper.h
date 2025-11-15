//
//  PMFileHelper.h
//  photo_manager
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///  Contains access file methods
@interface PMFileHelper : NSObject

+(void)deleteFile:(NSString *)path isDirectory:(BOOL)isDirectory error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
