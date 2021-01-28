//
//  PMProgressHandler.h
//  path_provider
//
//  Created by jinglong cai on 2021/1/15.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
NS_ASSUME_NONNULL_BEGIN

typedef enum PMProgressState{
  PMProgressStatePrepare = 0,
  PMProgressStateLoading = 1,
  PMProgressStateSuccess = 2,
  PMProgressStateFailed = 3,
} PMProgressState;

@interface PMProgressHandler : NSObject

@property(nonatomic, assign)int channelIndex;

- (void)notify:(double)progress state:(PMProgressState)state;

- (void)register:(NSObject <FlutterPluginRegistrar> *)registrar channelIndex:(int)index;

- (void)deinit;

@end

NS_ASSUME_NONNULL_END
