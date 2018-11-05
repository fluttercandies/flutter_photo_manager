# photo_manager

[![pub package](https://img.shields.io/pub/v/photo_manager.svg)](https://pub.dartlang.org/packages/photo_manager)
![Hex.pm](https://img.shields.io/hexpm/l/plug.svg)

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
  photo_manager: ^0.1.5
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
```
