# photo_manager

[![pub package](https://img.shields.io/pub/v/photo_manager.svg)](https://pub.dartlang.org/packages/photo_manager)
[![GitHub](https://img.shields.io/github/license/Caijinglong/flutter_photo_manager.svg)](https://github.com/Caijinglong/flutter_photo_manager)
[![GitHub stars](https://img.shields.io/github/stars/Caijinglong/flutter_photo_manager.svg?style=social&label=Stars)](https://github.com/Caijinglong/flutter_photo_manager)

A flutter api for photo, you can get image/video from ios or android.

一个提供相册 api 的插件, android ios 可用,没有 ui,以便于自定义自己的界面, 你可以通过提供的 api 来制作图片相关的 ui 或插件

If you just need a picture selector, you can choose to use [photo](https://pub.dartlang.org/packages/photo) library , a multi image picker. All UI create by flutter.

## install

the latest version is [![pub package](https://img.shields.io/pub/v/photo_manager.svg)](https://pub.dartlang.org/packages/photo_manager)

```yaml
dependencies:
  photo_manager: $latest_version
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
    /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
}
```

2. you get all of asset list (gallery)

```dart
List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
```

or

```dart
List<AssetPathEntity> list = await PhotoManager.getImageAsset();
```

or

```dart
List<AssetPathEntity> list = await PhotoManager.getVideoAsset();
```

3. get asset list from imagePath

paged:

```dart
// page: The page number of the page, starting at 0.
// perPage: The number of pages per page.
final assetList = await path.getAssetListPaged(page, perPage);
```

The old version, it is not recommended for continued use, because there may be performance issues on some phones. Now the internal implementation of this method is also paged, but the paged count is assetCount of AssetPathEntity.

Old version:

```dart
AssetPathEntity data = list[0]; // 1st album in the list, typically the "Recent" or "All" album
List<AssetEntity> imageList = await data.assetList;
```

1. use the AssetEntity

```dart
AssetEntity entity = imageList[0];

File file = await entity.file; // image file

List<int> fileData = await entity.fullData; // image/video file bytes

Uint8List thumbBytes = await entity.thumbData; // thumb data ,you can use Image.memory(thumbBytes); size is 64px*64px;

Uint8List thumbDataWithSize = await entity.thumbDataWithSize(width,height); //Just like thumbnails, you can specify your own size. unit is px;

AssetType type = entity.type; // the type of asset enum of other,image,video

Duration duration = entity.videoDuration; //if type is not video, then return null.

Size size = entity.size

int width = entity.width;

int height = entity.height;
```

## Usage

### Create `AssetEntity` with id

the `id` is `AssetEntity.id`

```dart
AssetEntity asset = await createAssetEntityWithId(id);
```

When this method is called, the image corresponding to ID has been deleted, and the return value is null.

### observer

use `addChangeCallback` to regiser observe.

```dart
PhotoManager.addChangeCallback(changeNotify);
PhotoManager.startChangeNotify();
```

```dart
PhotoManager.removeChangeCallback(changeNotify);
PhotoManager.stopChangeNotify();
```

## iOS plist config

Because the album is a privacy privilege, you need user permission to access it. You must to modify the `Info.plist` file in Runner project.

like next

```xml
    <key>NSPhotoLibraryUsageDescription</key>
    <string>App need your agree, can visit your album</string>
```

xcode like image
![in xcode](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/flutter_photo2.png)

## android config

### about androidX

Google recommends completing all support-to-AndroidX migrations in 2019. Documentation is also provided.

This library has been migrated in version 0.2.2, but it brings a problem. Sometimes your upstream library has not been migrated yet. At this time, you need to add an option to deal with this problem.

The complete migration method can be consulted [gitbook](https://caijinglong.gitbooks.io/migrate-flutter-to-androidx/content/).

### Android Q privacy

Now, the android part of the plugin uses api 29 to compile the plugin, so your android sdk environment must contain api 29 (androidQ).

AndroidQ has a new privacy policy, users can't access the original file.

If your compileSdkVersion and targetSdkVersion are both below 28, you can use `PhotoManager.forceOldApi` to force the old api to access the album. If you are not sure about this part, don't call this method.

### glide

Android native use glide to create image thumb bytes, version is 4.9.0.

If your other android library use the library, and version is not same, then you need edit your android project's build.gradle.

```gradle
rootProject.allprojects {

    subprojects {
        project.configurations.all {
            resolutionStrategy.eachDependency { details ->
                if (details.requested.group == 'com.github.bumptech.glide'
                        && details.requested.name.contains('glide')) {
                    details.useVersion "4.9.0"
                }
            }
        }
    }
}
```

## common issues

### ios build error

if your flutter print like the log. see [stackoverflow](https://stackoverflow.com/questions/27776497/include-of-non-modular-header-inside-framework-module)

```bash
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
