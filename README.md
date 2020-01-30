# photo_manager

[![pub package](https://img.shields.io/pub/v/photo_manager.svg)](https://pub.dartlang.org/packages/photo_manager)
[![GitHub](https://img.shields.io/github/license/Caijinglong/flutter_photo_manager.svg)](https://github.com/Caijinglong/flutter_photo_manager)
[![GitHub stars](https://img.shields.io/github/stars/Caijinglong/flutter_photo_manager.svg?style=social&label=Stars)](https://github.com/Caijinglong/flutter_photo_manager)

A flutter api for photo, you can get image/video from ios or android.

一个提供相册 api 的插件, android ios 可用,没有 ui,以便于自定义自己的界面, 你可以通过提供的 api 来制作图片相关的 ui 或插件

If you just need a picture selector, you can choose to use [photo](https://pub.dartlang.org/packages/photo) library , a multi image picker. All UI create by flutter.

- [photo_manager](#photo_manager)
  - [install](#install)
    - [Add to pubspec](#add-to-pubspec)
    - [import in dart code](#import-in-dart-code)
  - [Usage](#usage)
    - [request permission](#request-permission)
    - [you get all of asset list (gallery)](#you-get-all-of-asset-list-gallery)
      - [FilterOption](#filteroption)
    - [Get asset list from `AssetPathEntity`](#get-asset-list-from-assetpathentity)
      - [paged](#paged)
      - [range](#range)
      - [Old version](#old-version)
    - [AssetEntity](#assetentity)
      - [location info of android Q](#location-info-of-android-q)
      - [Origin description](#origin-description)
    - [observer](#observer)
    - [Experimental](#experimental)
      - [Delete item](#delete-item)
      - [Insert new item](#insert-new-item)
  - [iOS plist config](#ios-plist-config)
  - [android config](#android-config)
    - [about androidX](#about-androidx)
    - [Android Q privacy](#android-q-privacy)
    - [glide](#glide)
  - [common issues](#common-issues)
    - [ios build error](#ios-build-error)

## install

### Add to pubspec

the latest version is [![pub package](https://img.shields.io/pub/v/photo_manager.svg)](https://pub.dartlang.org/packages/photo_manager)

```yaml
dependencies:
  photo_manager: $latest_version
```

### import in dart code

```dart
import 'package:photo_manager/photo_manager.dart';
```

## Usage

### request permission

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

### you get all of asset list (gallery)

```dart
List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
```

| name          | description                                                                                   |
| ------------- | --------------------------------------------------------------------------------------------- |
| hasAll        | Is there an album containing "all"                                                            |
| type          | image/video/all , default all.                                                                |
| fetchDateTime | Only include resources older than that time.(Will be included in filterOption in the future.) |
| fliterOption  | See FilterOption.                                                                             |

#### FilterOption

| name               | description                                                                                                                                                                               |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| needTitle          | The title attribute of the picture must be included in android (even if it is false), it is more performance-consuming in iOS, please consider whether you need it. The default is false. |
| sizeConstraint     | Constraints on resource size.                                                                                                                                                             |
| durationConstraint | Constraints of time, pictures will ignore this constraint.                                                                                                                                |

Example see [filter_option_page.dart](https://github.com/CaiJingLong/flutter_photo_manager/blob/filter-option/example/lib/page/filter_option_page.dart).

### Get asset list from `AssetPathEntity`

#### paged

```dart
// page: The page number of the page, starting at 0.
// perPage: The number of pages per page.
final assetList = await path.getAssetListPaged(page, perPage);
```

The old version, it is not recommended for continued use, because there may be performance issues on some phones. Now the internal implementation of this method is also paged, but the paged count is assetCount of AssetPathEntity.

#### range

```dart
final assetList = await path.getAssetListRange(start: 0, end: 88); // use start and end to get asset.
// Example: 0~10 will return 10 assets. Special case: If there are only 5, return 5
```

#### Old version

```dart
AssetPathEntity data = list[0]; // 1st album in the list, typically the "Recent" or "All" album
List<AssetEntity> imageList = await data.assetList;
```

### AssetEntity

```dart
AssetEntity entity = imageList[0];

File file = await entity.file; // image file

Uint8List originBytes = await entity.originBytes; // image/video original file content,

Uint8List thumbBytes = await entity.thumbData; // thumb data ,you can use Image.memory(thumbBytes); size is 64px*64px;

Uint8List thumbDataWithSize = await entity.thumbDataWithSize(width,height); //Just like thumbnails, you can specify your own size. unit is px; format is optional support jpg and png.

AssetType type = entity.type; // the type of asset enum of other,image,video

Duration duration = entity.videoDuration; //if type is not video, then return null.

Size size = entity.size

int width = entity.width;

int height = entity.height;

DateTime createDt = entity.createDateTime;

DateTime modifiedDt = entity.modifiedDateTime;

/// Gps info of asset. If latitude and longitude is 0, it means that no positioning information was obtained.
/// This information is not necessarily available, because the photo source is not necessarily the camera.
/// Even the camera, due to privacy issues, this property must not be available on androidQ and above.
double latitude = entity.latitude;
double longitude = entiry.longitude;

Latlng latlng = await entity.latlngAsync(); // In androidQ or higher, need use the method to get location info.
```

#### location info of android Q

Because of AndroidQ's privacy policy issues, it is necessary to locate permissions in order to obtain the original image, and to obtain location information by reading the Exif metadata of the data.

#### Origin description

The `originFile` and `originBytes` will return the original content.

Not guaranteed to be available in flutter.  
Because flutter's Image does not support heic.  
The video is also the original format, non-exported format, compatibility does not guarantee usability.

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

### Experimental

#### Delete item

```dart
final List<String> result = await PhotoManager.editor.deleteWithIds([entity.id]); // The deleted id will be returned, if it fails, an empty array will be returned.
```

Tip: You need to call the corresponding `PathEntity`'s `refreshPathProperties` method to refresh the latest assetCount.

And [range](#range) way to get the latest data to ensure the accuracy of the current data. Such as [example](https://github.com/CaiJingLong/flutter_photo_manager/blob/0298d19464c05b231e2e97989f068ec3a72b0ab0/example/lib/model/photo_provider.dart#L104-L113).

#### Insert new item

```dart
final AssetEntity imageEntity = await PhotoManager.editor.saveImage(uint8list); // nullable


File videoFile = File("video path");
final AssetEntity videoEntity = await await PhotoManager.editor.saveVideo(videoFile); // nullable
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

In ios11+, if you want to save or delete asset, you also need add `NSPhotoLibraryAddUsageDescription` to plist.

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
