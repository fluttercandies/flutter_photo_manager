#import "PMImport.h"
#import "PMProgressHandlerProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PMProgressHandler : NSObject <PMProgressHandlerProtocol>

@property(nonatomic, assign) int channelIndex;

- (void)notify:(double)progress state:(PMProgressState)state;

- (void)register:(NSObject <FlutterPluginRegistrar> *)registrar channelIndex:(int)index;

@end

NS_ASSUME_NONNULL_END
