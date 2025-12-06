#import "NSString+PM_COMMON.h"
#import "PMRequestTypeUtils.h"

#import <Photos/Photos.h>

#define PM_TYPE_IMAGE 1
#define PM_TYPE_VIDEO 1<<1
#define PM_TYPE_AUDIO 1<<2

@implementation PMRequestTypeUtils {
    
}

+ (BOOL)checkContainsType:(int)type targetType:(int)targetType {
    return (type & targetType) == targetType;
}

+ (BOOL)containsImage:(int)type {
    return [self checkContainsType:type targetType:PM_TYPE_IMAGE];
}

+ (BOOL)containsVideo:(int)type {
    return [self checkContainsType:type targetType:PM_TYPE_VIDEO];
}

+ (BOOL)containsAudio:(int)type {
    return [self checkContainsType:type targetType:PM_TYPE_AUDIO];
}

+ (PHFetchOptions *)getFetchOptionsByType:(int)type {
    // When filterOption is nil, we still need to filter by media type
    PHFetchOptions *options = [PHFetchOptions new];
    
    BOOL containsImage = [PMRequestTypeUtils containsImage:type];
    BOOL containsVideo = [PMRequestTypeUtils containsVideo:type];
    BOOL containsAudio = [PMRequestTypeUtils containsAudio:type];
    
    NSMutableString *typeWhere = [NSMutableString new];
    NSMutableArray *args = [NSMutableArray new];
    
    if (containsImage) {
        [typeWhere appendString:@"mediaType == %d"];
        [args addObject:@(PHAssetMediaTypeImage)];
    }
    if (containsVideo) {
        if (![typeWhere isEmpty]) {
            [typeWhere appendString:@" OR "];
        }
        [typeWhere appendString:@"mediaType == %d"];
        [args addObject:@(PHAssetMediaTypeVideo)];
    }
    if (containsAudio) {
        if (![typeWhere isEmpty]) {
            [typeWhere appendString:@" OR "];
        }
        [typeWhere appendString:@"mediaType == %d"];
        [args addObject:@(PHAssetMediaTypeAudio)];
    }
    
    if (![typeWhere isEmpty]) {
        options.predicate = [NSPredicate predicateWithFormat:typeWhere argumentArray:args];
    }
    
    return options;
}

@end
