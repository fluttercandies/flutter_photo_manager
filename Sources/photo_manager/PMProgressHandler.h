//
//  PMProgressHandler.h
//  path_provider
//

#import <Foundation/Foundation.h>
#import "PMProgressHandlerProtocol.h"
#import "PMImport.h"

NS_ASSUME_NONNULL_BEGIN

@interface PMProgressHandler : NSObject <PMProgressHandlerProtocol>

@property(nonatomic, assign) int channelIndex;

- (void)notify:(double)progress state:(PMProgressState)state;

- (void)register:(NSObject <FlutterPluginRegistrar> *)registrar channelIndex:(int)index;

@end

NS_ASSUME_NONNULL_END
