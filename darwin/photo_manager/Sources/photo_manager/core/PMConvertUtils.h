#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "PMBaseFilter.h"

@class PMAssetPathEntity;
@class PMAssetEntity;
@class PMFilterOption;
@class PMFilterOptionGroup;

@interface PMConvertUtils : NSObject

+ (NSDictionary *)convertPathToMap:(NSArray<PMAssetPathEntity *> *)array;

+ (NSDictionary *)convertAssetToMap:(NSArray<PMAssetEntity *> *)array
                        optionGroup:(NSObject<PMBaseFilter> *)optionGroup;

+ (NSDictionary *)convertPHAssetToMap:(PHAsset *)asset
                            needTitle:(BOOL)needTitle;

+ (NSDictionary *)convertPMAssetToMap:(PMAssetEntity *)asset
                            needTitle:(BOOL)needTitle;

+ (PMFilterOption *)convertMapToPMFilterOption:(NSDictionary *)map;

+ (NSObject<PMBaseFilter> *)convertMapToOptionContainer:(NSDictionary *)map;

+ (AVFileType)convertNumberToAVFileType:(int)number;

+ (NSString *)convertAVFileTypeToExtension:(AVFileType)fileType;
@end
