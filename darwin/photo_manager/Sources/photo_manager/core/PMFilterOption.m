#import <Photos/Photos.h>
#import "PMFilterOption.h"
#import "PMRequestTypeUtils.h"
#import "NSString+PM_COMMON.h"
#import "PMLogUtils.h"

@implementation PMFilterOptionGroup {

}

- (NSArray<NSSortDescriptor *> *)sortCond {
    if (self.sortArray == nil || self.sortArray.count == 0) {
        return nil;
    }
    return self.sortArray;
}

- (void)injectSortArray:(NSArray *)array {
    NSMutableArray<NSSortDescriptor *> *result = [NSMutableArray new];

    // Handle platform default sorting first.
    if (array.count == 0) {
        // Set an empty sort array directly.
        self.sortArray = nil;
        return;
    }

    for (NSDictionary *dict in array) {
        int typeValue = [dict[@"type"] intValue];
        BOOL asc = [dict[@"asc"] boolValue];

        NSString *key = nil;
        if (typeValue == 0) {
            key = @"creationDate";
        } else if (typeValue == 1) {
            key = @"modificationDate";
        }

        if (key) {
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:asc];
            if (descriptor) {
                [result addObject:descriptor];
            }
        }
    }

    self.sortArray = result;
}

- (PHFetchOptions *)getFetchOptions:(int)type {
    PMFilterOptionGroup *optionGroup = self;

    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = [optionGroup sortCond];
    
    // 获取 includeHiddenAssets 属性
    options.includeHiddenAssets = optionGroup.includeHiddenAssets;

    NSMutableString *cond = [NSMutableString new];
    NSMutableArray *args = [NSMutableArray new];

    BOOL containsImage = [PMRequestTypeUtils containsImage:type];
    BOOL containsVideo = [PMRequestTypeUtils containsVideo:type];
    BOOL containsAudio = [PMRequestTypeUtils containsAudio:type];

    if (containsImage) {
        [cond appendString:@" ( "];

        PMFilterOption *imageOption = optionGroup.imageOption;

        NSString *sizeCond = [imageOption sizeCond];
        NSArray *sizeArgs = [imageOption sizeArgs];

        [cond appendString:@"mediaType == %d"];
        [args addObject:@(PHAssetMediaTypeImage)];

        if (!imageOption.sizeConstraint.ignoreSize) {
            [cond appendString:@" AND "];
            [cond appendString:sizeCond];
            [args addObjectsFromArray:sizeArgs];
        }
        if (@available(iOS 9.1, *)) {
            if (optionGroup.onlyLivePhotos) {
                [cond appendString:@" AND "];
                [cond appendString:[NSString
                    stringWithFormat:@"( ( mediaSubtype & %lu ) == 8 )",
                                     (unsigned long) PHAssetMediaSubtypePhotoLive]
                ];
            } else if (!optionGroup.containsLivePhotos) {
                [cond appendString:@" AND "];
                [cond appendString:[NSString
                    stringWithFormat:@"NOT ( ( mediaSubtype & %lu ) == 8 )",
                                     (unsigned long) PHAssetMediaSubtypePhotoLive]
                ];
            }
        }

        [cond appendString:@" )"];
    }

    if (containsVideo) {
        if (![cond isEmpty]) {
            [cond appendString:@" OR"];
        }

        [cond appendString:@" ( "];

        PMFilterOption *videoOption = optionGroup.videoOption;

        [cond appendString:@"mediaType == %d"];
        [args addObject:@(PHAssetMediaTypeVideo)];

        NSString *durationCond = [videoOption durationCond];
        NSArray *durationArgs = [videoOption durationArgs];
        [cond appendString:@" AND "];
        [cond appendString:durationCond];
        [args addObjectsFromArray:durationArgs];

        [cond appendString:@" ) "];
    }

    if (containsAudio) {
        if (![cond isEmpty]) {
            [cond appendString:@" OR "];
        }

        [cond appendString:@" ( "];

        PMFilterOption *audioOption = optionGroup.audioOption;

        [cond appendString:@"mediaType == %d"];
        [args addObject:@(PHAssetMediaTypeAudio)];

        NSString *durationCond = [audioOption durationCond];
        NSArray *durationArgs = [audioOption durationArgs];
        [cond appendString:@" AND "];
        [cond appendString:durationCond];
        [args addObjectsFromArray:durationArgs];

        [PMLogUtils.sharedInstance info:[NSString stringWithFormat:@"duration = %.2f ~ %.2f",
                                                                   [durationArgs[0] floatValue],
                                                                   [durationArgs[1] floatValue]]];

        [cond appendString:@" ) "];
    }

    [cond insertString:@"(" atIndex:0];
    [cond appendString:@")"];

    PMDateOption *dateOption = optionGroup.dateOption;
    if (!dateOption.ignore) {
        [cond appendString:[dateOption dateCond:@"creationDate"]];
        [args addObjectsFromArray:[dateOption dateArgs]];
    }

    PMDateOption *updateOption = optionGroup.updateOption;
    if (!updateOption.ignore) {
        [cond appendString:[updateOption dateCond:@"modificationDate"]];
        [args addObjectsFromArray:[updateOption dateArgs]];
    }

    options.predicate = [NSPredicate predicateWithFormat:cond argumentArray:args];

    return options;
}

- (BOOL)needTitle {
    return self.videoOption.needTitle || self.imageOption.needTitle;
}


@end

@implementation PMFilterOption {

}
- (NSString *)sizeCond {
    return @"pixelWidth >=%d AND pixelWidth <=%d AND pixelHeight >=%d AND pixelHeight <=%d";
}

- (NSArray *)sizeArgs {
    PMSizeConstraint constraint = self.sizeConstraint;
    return @[@(constraint.minWidth), @(constraint.maxWidth), @(constraint.minHeight), @(constraint.maxHeight)];
}


- (NSString *)durationCond {
    NSString *baseCond = @"duration >= %f AND duration <= %f";
    if (self.durationConstraint.allowNullable) {
        return [NSString stringWithFormat:@"( duration == nil OR ( %@ ) )", baseCond];
    }
    return baseCond;
}

- (NSArray *)durationArgs {
    PMDurationConstraint constraint = self.durationConstraint;
    return @[@(constraint.minDuration), @(constraint.maxDuration)];
}

@end


@implementation PMDateOption {

}

- (NSString *)dateCond:(NSString *)key {
    NSMutableString *str = [NSMutableString new];

    [str appendString:@" AND "];
    [str appendString:@"( "];

    // min

    [str appendString:key];
    [str appendString:@" >= %@"];


    // and
    [str appendString:@" AND "];

    // max

    [str appendString:key];
    [str appendString:@" <= %@ "];

    [str appendString:@") "];

    return str;
}

- (NSArray *)dateArgs {
    return @[self.min, self.max];
}

@end

@implementation PMCustomFilterOption {

}

- (NSString *)where {
    return self.params[@"where"];
}

- (NSArray<NSSortDescriptor *> *)sortDescriptors {
    NSMutableArray *sortDescriptors = [NSMutableArray new];
    NSArray *array = self.params[@"orderBy"];

    for (NSDictionary *dict in array) {
        NSString *column = dict[@"column"];
        BOOL ascending = [dict[@"isAsc"] boolValue];
        [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:column ascending:ascending]];
    }

    return sortDescriptors;
}

- (PHFetchOptions *)getFetchOptions:(int)type {
    PHFetchOptions *options = [PHFetchOptions new];
    
    // 从 params 中获取 includeHiddenAssets 属性
    options.includeHiddenAssets = self.params[@"includeHiddenAssets"] ? [self.params[@"includeHiddenAssets"] boolValue] : NO;

    BOOL containsImage = [PMRequestTypeUtils containsImage:type];
    BOOL containsVideo = [PMRequestTypeUtils containsVideo:type];
    BOOL containsAudio = [PMRequestTypeUtils containsAudio:type];
    
    NSMutableString *typeWhere = [NSMutableString new];
    
    if (containsImage) {
        if (!typeWhere.isEmpty) {
            [typeWhere appendString:@" OR "];
        }
        
        [typeWhere appendFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    }
    if (containsVideo) {
        if (!typeWhere.isEmpty) {
            [typeWhere appendString:@" OR "];
        }
        
        [typeWhere appendFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    }
    if (containsAudio) {
        if (!typeWhere.isEmpty) {
            [typeWhere appendString:@" OR "];
        }
        
        [typeWhere appendFormat:@"mediaType == %ld", PHAssetMediaTypeAudio];
    }

    NSString *where = [self where];
    if (!where.isEmpty) {
        NSString *text = [NSString stringWithFormat:@"%@ AND ( %@ )", where, typeWhere];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: text];
        options.predicate = predicate;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: typeWhere];
        options.predicate = predicate;
    }

    options.sortDescriptors = [self sortDescriptors];

    return options;
}

- (BOOL)containsModified {
    return [self.params[@"containsPathModified"] boolValue];
}

- (BOOL)needTitle {
    return [self.params[@"needTitle"] boolValue];
}

@end
