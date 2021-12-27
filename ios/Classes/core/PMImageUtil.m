//
//  PMImageUtil.m
//  path_provider_macos
//

#import "PMImageUtil.h"

@implementation PMImageUtil

+ (NSData *)convertToData:(PMImage *)image formatType:(PMThumbFormatType)type quality:(float)quality {
    
#if TARGET_OS_OSX
    
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSData *resultData;
    if (type == PMThumbFormatTypePNG) {
        resultData = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    } else {
        resultData = [imageRep representationUsingType:NSBitmapImageFileTypeJPEG properties:@{
            NSImageCompressionFactor: @(quality)
        }];
    }
    
    return resultData;
    
#endif
    
#if TARGET_OS_IOS
    NSData *resultData;
    if (type == PMThumbFormatTypePNG) {
        resultData = UIImagePNGRepresentation(image);
    } else {
        resultData = UIImageJPEGRepresentation(image, quality);
    }
    
    return resultData;
    
#endif
}


@end
