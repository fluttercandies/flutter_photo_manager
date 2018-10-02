# photo_manager

A flutter api for photo, you can get photo from ios or android

一个提供相册api的插件, android ios 可用,没有ui,以便于自定义自己的界面, 你可以通过提供的api来制作图片相关的ui或插件

or use [photo](https://pub.dartlang.org/photo) library , a multi image picker .All UI comes from flutter.

## install
  photo: ^0.0.1

## import

```dart
import 'package:photo_manager/photo_manager.dart';
```

## use
see the example/lib/main.dart

or see next

## example

1. you must requestPermission

```dart
var result = await PhotoManager.requestPermission();
if(result == true){
    // success
}else{
    // fail
}
```

2. you get all of imagePath(gallery)
```dart
List<ImagePathEntity> list = await PhotoManager.getImagePathList();
```

3. get image list from imagePath
```dart
List<ImageEntity> imageList = await data.imageList;
```

4. use the imageEntity

```dart
ImageEntity entity = imageList[0];
File file = await entity.file; // image file

List<int> fileData = await entity.fullData; // image file bytes

Uint8List thumbBytes = await entity.thumbData; // thumb data ,you can use Image.memory(thumbBytes); size is 64px*64px;

Uint8List thumbDataWithSize = await entity.thumbDataWithSize(width,height); //Just like thumbnails, you can specify your own size. unit is px;

```