//
// Created by jinglong cai on 2020/9/25.
//

#import <Foundation/Foundation.h>


typedef enum PMThumbFormatType {
  PMThumbFormatTypeJPEG,
  PMThumbFormatTypePNG,
} PMThumbFormatType;

@interface PMThumbLoadOption : NSObject

@property(nonatomic, assign) int width;
@property(nonatomic, assign) int height;
@property(nonatomic, assign) PMThumbFormatType format;
@property(nonatomic, assign) float quality;

+ (instancetype)optionDict:(NSDictionary *)dict;

@end