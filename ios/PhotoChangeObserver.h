//
// Created by Caijinglong on 2019-02-26.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface PhotoChangeObserver : NSObject
- (void)initWithRegister:(NSObject <FlutterPluginRegistrar> *)registrar;
@end