//
// Created by jinglong cai on 2023/7/18.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface PMPathFilterOption : NSObject

+ (instancetype)optionWithDict:(NSDictionary *)dict;

@property(nonatomic, strong) NSArray *type;
@property(nonatomic, assign) NSArray *subType;

@end