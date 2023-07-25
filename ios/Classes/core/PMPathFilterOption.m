//
// Created by jinglong cai on 2023/7/18.
//

#import "PMPathFilterOption.h"


@implementation PMPathFilterOption {

}
+ (instancetype)optionWithDict:(NSDictionary *)dict {
    PMPathFilterOption *option = [PMPathFilterOption new];
    NSDictionary *darwinDict = dict[@"darwin"];

    option.type = darwinDict[@"type"];;
    option.subType = darwinDict[@"subType"];;

    return option;
}

@end