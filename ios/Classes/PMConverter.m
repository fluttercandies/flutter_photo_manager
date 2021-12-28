#import "PMConverter.h"
#import "PMImport.h"

@implementation PMConverter {
    
}

- (id)convertData:(NSData *)data {
    return [FlutterStandardTypedData typedDataWithBytes:data];
}

@end
