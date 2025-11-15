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

+ (PMImage *)scaleImage:(PMImage *)image withSize:(CGSize)size contentMode:(PHImageContentMode)contentMode {
    if (contentMode == PHImageContentModeAspectFill) {
        return [self scaleImageToFill:image withSize:size];
    }
    return [self scaleImageToFit:image withSize:size];
}

+ (PMImage *)scaleImageToFit:(PMImage *)image withSize:(CGSize)size {
    CGFloat aspect = image.size.width / image.size.height;
    CGFloat targetAspect = size.width / size.height;
    CGRect drawRect;
    if (aspect > targetAspect) {
        CGFloat width = size.height * aspect;
        drawRect = CGRectMake((size.width - width) / 2, 0, width, size.height);
    } else {
        CGFloat height = size.width / aspect;
        drawRect = CGRectMake(0, (size.height - height) / 2, size.width, height);
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [image drawInRect:drawRect];
    UIImage *thumb = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumb;
}

+ (PMImage *)scaleImageToFill:(PMImage *)image withSize:(CGSize)size {
    CGFloat aspect = image.size.width / image.size.height;
    CGFloat targetAspect = size.width / size.height;
    CGRect drawRect;
    if (aspect > targetAspect) {
        CGFloat height = size.width / aspect;
        CGFloat y = (size.height - height) / 2;
        drawRect = CGRectMake(0, y, size.width, height);
    } else {
        CGFloat width = size.height * aspect;
        CGFloat x = (size.width - width) / 2;
        drawRect = CGRectMake(x, 0, width, size.height);
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [image drawInRect:drawRect];
    UIImage *thumb = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumb;
}



@end
