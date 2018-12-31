# photo_manager

[![pub package](https://img.shields.io/pub/v/photo_manager.svg)](https://pub.dartlang.org/packages/photo_manager)
[![GitHub](https://img.shields.io/github/license/Caijinglong/flutter_photo_manager.svg)](https://github.com/Caijinglong/flutter_photo_manager)
[![GitHub stars](https://img.shields.io/github/stars/Caijinglong/flutter_photo_manager.svg?style=social&label=Stars)](https://github.com/Caijinglong/flutter_photo_manager)

A flutter api for photo, you can get image/video from ios or android

一个提供相册 api 的插件, android ios 可用,没有 ui,以便于自定义自己的界面, 你可以通过提供的 api 来制作图片相关的 ui 或插件

or use [photo](https://pub.dartlang.org/packages/photo) library , a multi image picker .All UI comes from flutter.

## api changed

in 0.1.0 API incompatibility

because support video, so rename api from ImageXXXX to AssetXXXX

so 0.1.X and 0.0.X incompatibility

## install

```yaml
dependencies:
  photo_manager: ^0.1.10
```

## import

```dart
import 'package:photo_manager/photo_manager.dart';
```

## use

see the example/lib/main.dart

or see next

## example

1. request permission

You must get the user's permission on android/ios.

```dart
var result = await PhotoManager.requestPermission();
if (result) {
    // success
} else {
    // fail
    // if result is fail, you can call PhotoManger.openSetting();  to open android/ios applicaton's setting to get permission
}
```

2. you get all of asset list (gallery)

```dart
List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
```

3. get asset list from imagePath

```dart
List<AssetEntity> imageList = await data.assetList;
```

4. use the AssetEntity

```dart
AssetEntity entity = imageList[0];

File file = await entity.file; // image file

List<int> fileData = await entity.fullData; // image/video file bytes

Uint8List thumbBytes = await entity.thumbData; // thumb data ,you can use Image.memory(thumbBytes); size is 64px*64px;

Uint8List thumbDataWithSize = await entity.thumbDataWithSize(width,height); //Just like thumbnails, you can specify your own size. unit is px;

AssetType type = entity.type; // the type of asset enum of other,image,video

Duration duration = await entity.duration; //if type is not video, then return null.
```

## about ios build error

if your flutter print like the log. see [so](https://stackoverflow.com/questions/27776497/include-of-non-modular-header-inside-framework-module)

```
Xcode's output:
↳
    === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Debug ===
    The use of Swift 3 @objc inference in Swift 4 mode is deprecated. Please address deprecated @objc inference warnings, test your code with “Use of deprecated Swift 3 @objc inference” logging enabled, and then disable inference by changing the "Swift 3 @objc Inference" build setting to "Default" for the "Runner" target.
    === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Debug ===
    While building module 'photo_manager' imported from /Users/cai/IdeaProjects/flutter/sxw_order/ios/Runner/GeneratedPluginRegistrant.m:9:
    In file included from <module-includes>:1:
    In file included from /Users/cai/IdeaProjects/flutter/sxw_order/build/ios/Debug-iphonesimulator/photo_manager/photo_manager.framework/Headers/photo_manager-umbrella.h:16:
    /Users/cai/IdeaProjects/flutter/sxw_order/build/ios/Debug-iphonesimulator/photo_manager/photo_manager.framework/Headers/MD5Utils.h:5:9: error: include of non-modular header inside framework module 'photo_manager.MD5Utils': '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator11.2.sdk/usr/include/CommonCrypto/CommonDigest.h' [-Werror,-Wnon-modular-include-in-framework-module]
    #import <CommonCrypto/CommonDigest.h>
            ^
    1 error generated.
    /Users/cai/IdeaProjects/flutter/sxw_order/ios/Runner/GeneratedPluginRegistrant.m:9:9: fatal error: could not build module 'photo_manager'
    #import <photo_manager/ImageScannerPlugin.h>
     ~~~~~~~^
    2 errors generated.
```

## about ios

Because the album is a privacy privilege, you need user permission to access it. You must to modify the `Info.plist` file in Runner project.

like next

```plist
    <key>NSPhotoLibraryUsageDescription</key>
    <string>App need your agree, can visit your album</string>
```

xcode like image
![in xcode](https://github.com/CaiJingLong/some_asset/blob/master/flutter_photo2.png)
