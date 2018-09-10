//
// Created by Caijinglong on 2018/9/10.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface ImageScanner : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {

}
@property(nonatomic, strong) NSObject <FlutterPluginRegistrar> *registrar;

- (void)getImageIdList:(FlutterMethodCall *)call result:(FlutterResult)result;

@end