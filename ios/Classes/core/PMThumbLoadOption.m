//
// Created by jinglong cai on 2020/9/25.
//

#import "PMThumbLoadOption.h"


@implementation PMThumbLoadOption {

}

+ (instancetype)optionDict:(NSDictionary *)dict {
    PMThumbLoadOption *option = [PMThumbLoadOption new];

    option.width = [dict[@"width"] intValue];
    option.height = [dict[@"height"] intValue];
    int quality = [dict[@"quality"] intValue];
    option.quality = (float) quality / 100;
    int format = [dict[@"format"] intValue];
    if (format == 0) {
        option.format = PMThumbFormatTypeJPEG;
    } else {
        option.format = PMThumbFormatTypePNG;
    }

    return option;
}

@end
