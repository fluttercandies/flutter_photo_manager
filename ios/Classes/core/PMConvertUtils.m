#import "PMConvertUtils.h"
#import "PHAsset+PM_COMMON.h"
#import "PMAssetPathEntity.h"
#import "PMFilterOption.h"

@implementation PMConvertUtils {
}

+ (NSDictionary *)convertPathToMap:(NSArray<PMAssetPathEntity *> *)array {
    NSMutableArray *data = [NSMutableArray new];
    
    for (PMAssetPathEntity *entity in array) {
        NSUInteger assetCount = entity.assetCount;
        if (assetCount == 0) {
            continue;
        }
        
        NSDictionary *item = @{
            @"id": entity.id,
            @"name": entity.name,
            @"isAll": @(entity.isAll),
            @"albumType": @(entity.type),
        };
        
        NSMutableDictionary *params = [NSMutableDictionary new];
        [params addEntriesFromDictionary:item];
        
        PHAssetCollection *collection = entity.collection;
        if (collection) {
            params[@"darwinAssetCollectionType"] = @(collection.assetCollectionType);
            params[@"darwinAssetCollectionSubtype"] = @(collection.assetCollectionSubtype);
        }
        
        if (assetCount != NSIntegerMax) {
            params[@"assetCount"] = @(assetCount);
        }
        if (entity.modifiedDate != 0) {
            params[@"modified"] = @(entity.modifiedDate);
        }
        
        [data addObject:params];
    }
    
    return @{@"data": data};
}

+ (NSDictionary *)convertAssetToMap:(NSArray<PMAssetEntity *> *)array
                        optionGroup:(NSObject <PMBaseFilter> *)optionGroup {
    NSMutableArray *data = [NSMutableArray new];
    
    BOOL videoShowTitle = optionGroup.needTitle;
    BOOL imageShowTitle = optionGroup.needTitle;
    
    for (PMAssetEntity *asset in array) {
        NSDictionary *item;
        if ([asset.phAsset isImage]) {
            item = [PMConvertUtils convertPMAssetToMap:asset needTitle:imageShowTitle];
        } else if ([asset.phAsset isVideo]) {
            item = [PMConvertUtils convertPMAssetToMap:asset needTitle:videoShowTitle];
        } else {
            continue;
        }
        [data addObject:item];
    }
    
    return @{@"data": data};
}

+ (NSDictionary *)convertPHAssetToMap:(PHAsset *)asset needTitle:(BOOL)needTitle {
    long createDt = (long) asset.creationDate.timeIntervalSince1970;
    long modifiedDt = (long) asset.modificationDate.timeIntervalSince1970;
    long duration = (long) asset.duration;
    
    int typeInt = 0;
    if (asset.isVideo) {
        typeInt = 2;
    } else if (asset.isImage) {
        typeInt = 1;
    } else if (asset.isAudio) {
        typeInt = 3;
    }
    
    return @{
        @"id": asset.localIdentifier,
        @"createDt": @(createDt),
        @"width": @(asset.pixelWidth),
        @"height": @(asset.pixelHeight),
        @"favorite": @(asset.favorite),
        @"duration": @(duration),
        @"type": @(typeInt),
        @"modifiedDt": @(modifiedDt),
        @"lng": @(asset.location.coordinate.longitude),
        @"lat": @(asset.location.coordinate.latitude),
        @"title": needTitle ? [asset title] : @"",
        @"subtype": @(asset.mediaSubtypes),
    };
}

+ (NSDictionary *)convertPMAssetToMap:(PMAssetEntity *)asset
                            needTitle:(BOOL)needTitle {
    return @{
        @"id": asset.id,
        @"createDt": @(asset.createDt),
        @"width": @(asset.width),
        @"height": @(asset.height),
        @"duration": @(asset.duration),
        @"favorite": @(asset.favorite),
        @"type": @(asset.type),
        @"modifiedDt": @(asset.modifiedDt),
        @"lng": @(asset.lng),
        @"lat": @(asset.lat),
        @"title": needTitle ? asset.title : @"",
        @"subtype": @(asset.subtype),
    };
}

+ (NSObject <PMBaseFilter> *)convertMapToOptionContainer:(NSDictionary *)map {
    int type = [map[@"type"] intValue];
    
    if (type == 0) {
        map = map[@"child"];
        
        PMFilterOptionGroup *container = [PMFilterOptionGroup alloc];
        NSDictionary *image = map[@"image"];
        NSDictionary *video = map[@"video"];
        NSDictionary *audio = map[@"audio"];
        
        container.imageOption = [self convertMapToPMFilterOption:image];
        container.videoOption = [self convertMapToPMFilterOption:video];
        container.audioOption = [self convertMapToPMFilterOption:audio];
        container.dateOption = [self convertMapToPMDateOption:map[@"createDate"]];
        container.updateOption = [self convertMapToPMDateOption:map[@"updateDate"]];
        container.containsModified = [map[@"containsPathModified"] boolValue];
        container.containsLivePhotos = [map[@"containsLivePhotos"] boolValue];
        container.onlyLivePhotos = [map[@"onlyLivePhotos"] boolValue];
        container.includeHiddenAssets = [map[@"includeHiddenAssets"] boolValue];
        
        NSArray *sortArray = map[@"orders"];
        [container injectSortArray:sortArray];
        
        return container;
    } else {
        PMCustomFilterOption *option = [PMCustomFilterOption new];
        option.params = map[@"child"];
        return option;
    }
}

+ (PMFilterOption *)convertMapToPMFilterOption:(NSDictionary *)map {
    PMFilterOption *option = [PMFilterOption new];
    option.needTitle = [map[@"title"] boolValue];
    
    NSDictionary *sizeMap = map[@"size"];
    PMSizeConstraint sizeConstraint;
    sizeConstraint.minWidth = [sizeMap[@"minWidth"] unsignedIntValue];
    sizeConstraint.maxWidth = [sizeMap[@"maxWidth"] unsignedIntValue];
    sizeConstraint.minHeight = [sizeMap[@"minHeight"] unsignedIntValue];
    sizeConstraint.maxHeight = [sizeMap[@"maxHeight"] unsignedIntValue];
    sizeConstraint.ignoreSize = [sizeMap[@"ignoreSize"] boolValue];
    option.sizeConstraint = sizeConstraint;
    
    NSDictionary *durationMap = map[@"duration"];
    PMDurationConstraint durationConstraint;
    durationConstraint.minDuration = [PMConvertUtils convertNSNumberToSecond:durationMap[@"min"]];
    durationConstraint.maxDuration = [PMConvertUtils convertNSNumberToSecond:durationMap[@"max"]];
    durationConstraint.allowNullable = [durationMap[@"allowNullable"] boolValue];
    option.durationConstraint = durationConstraint;
    
    return option;
}

+ (PMDateOption *)convertMapToPMDateOption:(NSDictionary *)map {
    PMDateOption *option = [PMDateOption new];
    
    long min = [map[@"min"] longValue];
    long max = [map[@"max"] longValue];
    BOOL ignore = [map[@"ignore"] boolValue];
    
    option.min = [NSDate dateWithTimeIntervalSince1970:(min / 1000.0)];
    option.max = [NSDate dateWithTimeIntervalSince1970:(max / 1000.0)];
    option.ignore = ignore;
    
    return option;
}

+ (double)convertNSNumberToSecond:(NSNumber *)number {
    unsigned int i = number.unsignedIntValue;
    return (double) i / 1000.0;
}

// TODO: Add macros.
+ (AVFileType)convertNumberToAVFileType:(int)number {
    if (number <= 0) {
        return nil;
    }
    NSMutableDictionary *map = [@{
        @1 : AVFileTypeQuickTimeMovie,
        @2 : AVFileTypeMPEG4,
        @3 : AVFileTypeAppleM4V,
        @4 : AVFileTypeAppleM4A,
        @5 : AVFileType3GPP,
        @6 : AVFileType3GPP2,
        @7 : AVFileTypeCoreAudioFormat,
        @8 : AVFileTypeWAVE,
        @9 : AVFileTypeAIFF,
        @10 : AVFileTypeAIFC,
        @11 : AVFileTypeAMR,
        @12 : AVFileTypeMPEGLayer3,
        @13 : AVFileTypeSunAU,
        @14 : AVFileTypeAC3,
        @15 : AVFileTypeEnhancedAC3
    } mutableCopy];
    AVFileType type = map[@(number)];
    if (type == nil) {
        return nil;
    }
    return type;
}

// TODO: Add macros.
+ (NSString *)convertAVFileTypeToExtension:(AVFileType)fileType {
    NSMutableDictionary<AVFileType, NSString *> *fileTypeToExtensionMap = [@{
        AVFileTypeQuickTimeMovie : @".mov",
        AVFileTypeMPEG4 : @".mp4",
        AVFileTypeAppleM4V : @".m4v",
        AVFileTypeAppleM4A : @".m4a",
        AVFileType3GPP : @".3gp",
        AVFileType3GPP2 : @".3g2",
        AVFileTypeCoreAudioFormat : @".caf",
        AVFileTypeWAVE : @".wav",
        AVFileTypeAIFF : @".aiff",
        AVFileTypeAIFC : @".aifc",
        AVFileTypeAMR : @".amr",
        AVFileTypeMPEGLayer3 : @".mp3",
        AVFileTypeSunAU : @".au",
        AVFileTypeAC3 : @".ac3",
        AVFileTypeEnhancedAC3 : @".eac3",
    } mutableCopy];
    return fileTypeToExtensionMap[fileType] ?: nil;  // Return nil if fileType is not found
}

@end
