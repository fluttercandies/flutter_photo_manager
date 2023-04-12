<!-- Copyright 2018 The FlutterCandies author. All rights reserved.
Use of this source code is governed by an Apache license
that can be found in the LICENSE file. -->

# photo_manager

[English](README.md) | 中文

[![pub package](https://img.shields.io/pub/v/photo_manager?label=stable)][pub package]
[![pub pre-release package](https://img.shields.io/pub/v/photo_manager?color=9d00ff&include_prereleases&label=dev)](https://pub.dev/packages/photo_manager)
[![Build status](https://img.shields.io/github/actions/workflow/status/fluttercandies/flutter_photo_manager/runnable.yml?branch=main&label=CI&logo=github&style=flat-square)](https://github.com/fluttercandies/flutter_photo_manager/actions/workflows/runnable.yml)
[![GitHub license](https://img.shields.io/github/license/fluttercandies/flutter_photo_manager)](https://github.com/fluttercandies/flutter_photo_manager/blob/main/LICENSE)

[![GitHub stars](https://img.shields.io/github/stars/fluttercandies/flutter_photo_manager?style=social&label=Stars)](https://github.com/fluttercandies/flutter_photo_manager/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/fluttercandies/flutter_photo_manager?logo=github&style=flat-square)](https://github.com/fluttercandies/flutter_photo_manager/network)
[![Awesome Flutter](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/Solido/awesome-flutter)
<a target="_blank" href="https://jq.qq.com/?_wv=1027&k=5bcc0gy"><img border="0" src="https://pub.idqqimg.com/wpa/images/group.png" alt="FlutterCandies" title="FlutterCandies"></a>

使用 photo_manager 插件可以轻松地获取设备中的相册和照片，并进行管理。
它提供了抽象的 API 来管理资源，不需要集成 UI 即可在 Android、iOS 和 macOS 上获取媒体资源（图像 / 视频 / 音频）。

## 集成此插件的精彩项目

| name                 | pub                                                                                                                | github                                                                                                                                                                  |
| :------------------- | :----------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| wechat_assets_picker | [![pub package](https://img.shields.io/pub/v/wechat_assets_picker)](https://pub.dev/packages/wechat_assets_picker) | [![star](https://img.shields.io/github/stars/fluttercandies/flutter_wechat_assets_picker?style=social)](https://github.com/fluttercandies/flutter_wechat_assets_picker) |
| wechat_camera_picker | [![pub package](https://img.shields.io/pub/v/wechat_camera_picker)](https://pub.dev/packages/wechat_camera_picker) | [![star](https://img.shields.io/github/stars/fluttercandies/flutter_wechat_camera_picker?style=social)](https://github.com/fluttercandies/flutter_wechat_camera_picker) |

## 关于此插件的文章

- [Hard to manage media with Flutter? Try photo_manager, the all-in-one solution](https://medium.flutter.cn/hard-to-manage-media-with-flutter-try-photo-manager-the-all-in-one-solution-5188599e4cf)

## 迁移指导

对于跨主要版本的升级，请查看 [migration guide](MIGRATION_GUIDE.md)  获取详细信息.

<!-- TOC -->
- [photo\_manager](#photo_manager)
  - [集成此插件的精彩项目](#集成此插件的精彩项目)
  - [关于此插件的文章](#关于此插件的文章)
  - [迁移指导](#迁移指导)
  - [常见问题](#常见问题)
  - [使用前准备](#使用前准备)
    - [请在 pubspec.yaml 中添加以下依赖：](#请在-pubspecyaml-中添加以下依赖)
    - [导入到你的项目中：](#导入到你的项目中)
    - [原生平台的配置](#原生平台的配置)
      - [Android 配置准备](#android-配置准备)
        - [Kotlin, Gradle, AGP](#kotlin-gradle-agp)
        - [Android 10+ (Q, 29)](#android-10-q-29)
        - [Glide](#glide)
      - [iOS 配置准备](#ios-配置准备)
  - [用法](#用法)
    - [权限请求](#权限请求)
      - [iOS上的部分媒体资源限制权限](#ios上的部分媒体资源限制权限)
    - [获取 `AssetPathEntity`](#获取-assetpathentity)
    - [获取资源 (`AssetEntity`)](#获取资源-assetentity)
      - [PMFilter](#pmfilter)
        - [PMFilterOptionGroup](#pmfilteroptiongroup)
        - [CustomFilter](#customfilter)
      - [通过 `AssetPathEntity` 获取 `AssetEntity`](#通过-assetpathentity-获取-assetentity)
      - [通过 `PhotoManager` (Since 2.6.0) 获取 `AssetEntity`](#通过-photomanager-since-260-获取-assetentity)
      - [通过 ID 获取 `AssetEntity`](#通过-id-获取-assetentity)
      - [通过 raw data 获取 `AssetEntity`](#通过-raw-data-获取-assetentity)
      - [通过 iCloud](#通过-icloud)
      - [Assets的显示](#assets的显示)
      - [获取 "实况照片"](#获取-实况照片)
        - [仅过滤“实况照片”](#仅过滤实况照片)
        - [通过“实况照片”来获取视频](#通过实况照片来获取视频)
      - [限制](#限制)
        - [Android 10 媒体位置权限](#android-10-媒体位置权限)
        - [原始数据的使用](#原始数据的使用)
        - [iOS上文件检索时间过长](#ios上文件检索时间过长)
    - [Entities change notify](#entities-change-notify)
  - [缓存机制](#缓存机制)
    - [Android缓存](#android缓存)
    - [iOS缓存](#ios缓存)
    - [清除缓存](#清除缓存)
  - [原生额外配置](#原生额外配置)
    - [安卓额外配置](#安卓额外配置)
      - [Glide issues](#glide-issues)
      - [Android 13 (API level 33) 额外配置](#android-13-api-level-33-额外配置)
    - [iOS额外配置](#ios额外配置)
      - [本地化的系统相册名](#本地化的系统相册名)
    - [实验性功能](#实验性功能)
      - [预加载缩略图](#预加载缩略图)
      - [删除 Entities](#删除-entities)
      - [复制 Entity](#复制-entity)
      - [仅适用于 Android 的功能](#仅适用于-android-的功能)
        - [将实体移动到另一个相册](#将实体移动到另一个相册)
        - [移除所有不存在的Entities](#移除所有不存在的entities)
      - [适用于 iOS 或 macOS 的功能](#适用于-ios-或-macos-的功能)
        - [创建一个文件夹](#创建一个文件夹)
        - [创建一个相簿](#创建一个相簿)
        - [从相册中删除 Entity](#从相册中删除-entity)
        - [删除一个路径实体](#删除一个路径实体)
<!-- TOC -->

## 常见问题

你可以在 [GitHub issues][] 上搜索到经常遇到的问题，比如构建错误，运行时异常等等。

## 使用前准备

### 请在 pubspec.yaml 中添加以下依赖：

有两种方式可以把依赖添加到你的项目中:

- **(推荐)** 运行  `flutter pub add photo_manager`.
- 或者直接添加到项目的 `pubspec.yaml` 中的 `dependencies` 部分:

```yaml
dependencies:
  photo_manager: $latest_version
```

目前最新的版本是:
[![pub package](https://img.shields.io/pub/v/photo_manager.svg)][pub package]

### 导入到你的项目中：

```dart
import 'package:photo_manager/photo_manager.dart';
```

### 原生平台的配置

最低的平台版本:
**Android API 16, iOS 9.0, macOS 10.15**.

- Android:  [Android 配置准备](#android-config-preparation).
- iOS:  [iOS 配置准备](#ios-config-preparation).
- macOS:  和iOS几乎一致。

#### Android 配置准备

##### Kotlin, Gradle, AGP

从 1.2.7 开始，插件使用 **Kotlin `1.5.21`** 和 **Android Gradle Plugin `4.1.0`** 来构建。
如果你的项目使用了低于此版本的Kotlin/Gradle/AGP，建议升级到大于或等于此版本的Kotlin/Gradle/AGP。

更具体的做法:

- 更新你的 Gradle version (`gradle-wrapper.properties`)
  到 `7.5.1` 或者最新版本。
- 更新你的 Kotlin version (`ext.kotlin_version`)
  到 `1.5.30` 或者最新版本。
- 更新你的 AGP version (`com.android.tools.build:gradle`)
  或者 `7.2.2` 或者最新版本。

##### Android 10+ (Q, 29)

_如果您没有使用29及以上的编译或目标版本，您可以跳过本节。_

在Android 10上，引入了 **Scoped Storage**，这会导致原始资源文件不能通过其文件路径直接访问。

如果你的  `compileSdkVersion` or `targetSdkVersion` 为 29,
为了能够成功获取到媒体资源，你可以考虑通过在 `AndroidManifest.xml` 中添加 `android:requestLegacyExternalStorage="true"`，如下所示:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.fluttercandies.photo_manager_example">

    <application
        android:label="photo_manager_example"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">
    </application>
</manifest>
```

**注意: 使用此标志的应用会被Google Play拒绝。**

这不是必须的，插件缓存文件的时候还是可以正常工作的。但是就要开发者主动去控制缓存了，最好的例子
就是每次启动APP的时候调用 [`PhotoManager.clearFileCache`] 去清理缓存文件。

##### Glide

本插件是使用 [Glide][] 在安卓上来创建缩略图文件的。

如果你发现 [Glide][] 出现了一些警告日志，那就说明主项目需要一个 `AppGlideModule` 的实现。
请查看 [Generated API][] 的实现方式。


#### iOS 配置准备

添加 `NSPhotoLibraryUsageDescription` 的字典到 `ios/Runner/Info.plist` 中：

```plist
<key>NSPhotoLibraryUsageDescription</key>
<string>In order to access your photo library</string>
```

在iOS 11或者更高版本中，如果你请求相册的写入权限的话，那么你就需要
添加 `NSPhotoLibraryAddUsageDescription` 的字典到 `ios/Runner/Info.plist`。

这和上面的相簿 `NSPhotoLibraryUsageDescription` 权限请求差不多

![permissions in Xcode](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/flutter_photo2.png)

## 用法

### 权限请求

大部分的 API 只在获取到权限后才能正常使用

```dart
final PermissionState _ps = await PhotoManager.requestPermissionExtend();
if (_ps.isAuth) {
  // 已获取到权限 Granted.
} else {

  // 权限受限制（iOS）或者被拒绝时，使用`==`能够更准确的判断 Limited(iOS) or Rejected, use `==` for more precise judgements.
  // 你可以使用`PhotoManager.openSetting()`去打开系统设置页面进行进一步的逻辑定制 You can call `PhotoManager.openSetting()` to open settings for further steps.
}
```

但是如果你非常肯定你的调用只会在获取到权限之后才会执行，那么你可以忽略权限的检查：

```dart
PhotoManager.setIgnorePermissionCheck(true);
```

#### iOS上的部分媒体资源限制权限 

随着 iOS14 的发布，苹果在iOS上引入了部分资源限制的权限 "Limited Photos Library"。
所以你需要使用[`PhotoManager.requestPermissionExtend`]来获取权限，
这个方法会返回当前的权限状态 [`PermissionState`]。
详情请参阅 [PHAuthorizationStatus][]。


如果想要重新选择在 APP 上能够获取到的资源，使用 [`PhotoManager.presentLimited`] 去调起重新选择资源的弹窗，
这个方法在 iOS14 以上版本生效，其他平台或版本无法调用这个 API


### 获取 `AssetPathEntity`

相簿或者文件夹以抽象类 [`AssetPathEntity`][] 的形式呈现，
在安卓中表示为一个资源桶 `MediaStore` ，在iOS/macOS中则是 `PHAssetCollection` 的对象。

获取所有相册：

```dart
final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();
```

详情请参阅 [`getAssetPathList`][]。

### 获取资源 (`AssetEntity`)

资源（图片/视频/音频）都是以抽象类 [`AssetEntity`][] 的方式呈现
在安卓中表示一系列 `MediaStore` 的字段，在iOS/macOS则是`PHAsset`的对象。


#### PMFilter

`PhotoManager` 获取 `AssetPathEntity` 时的一些方法拥有 `PMFilter` 参数。
这个参数用于根据条件过滤资源。

- PhotoManager
  - getAssetPathList (通过此方法传递过滤参数能够传递进资源路径实体 [`AssetPathEntity`][] 选择后的结果中)
  - getAssetCount
  - getAssetListRange
  - getAssetListPaged
- AssetPathEntity
  - constructor (不推荐开发者使用构造器自行创建资源)
  - fromId
  - obtainPathFromProperties (不推荐使用属性去获取路径)

`PMFilter`  有两个实现：
- [PMFilterOptionGroup](#PMFilterOptionGroup)
- [CustomFilter](#CustomFilter)

##### PMFilterOptionGroup

在2.6.0之前，这是唯一的实现方式。

```dart
final FilterOptionGroup filterOption = FilterOptionGroup(
  imageOption: FilterOption(
    sizeConstraint: SizeConstraint(
      maxWidth: 10000,
      maxHeight: 10000,
      minWidth: 100,
      minHeight: 100,
      ignoreSize: false,
    ),
  ),
  videoOption: FilterOption(
    durationConstraint: DurationConstraint(
      min: Duration(seconds: 1),
      max: Duration(seconds: 30),
      allowNullable: false,
    ),
  ),
  createTimeCondition: DateTimeCondition(
    min: DateTime(2020, 1, 1),
    max: DateTime(2020, 12, 31),
  ),
  orders: [
    OrderOption(
      type: OrderOptionType.createDate,
      asc: false,
    ),
  ],
  /// other options
);
```

##### CustomFilter

这是实验性的功能，如果在使用自定过滤器上遇到任何问题欢迎按照模板提交 issue

[`CustomFilter`] 自定义过滤器是在插件的2.6.0的版本时添加的，
它能针对不同平台提供更加灵活的筛选条件。

这更加接近原生的使用方式，你可以自定义任意的筛选和排序的条件。


**类 SQL** 的用法：


[`SqlCustomFilter`] 能够构造出类似SQL语句一样的查询过滤方式，但是 iOS 或者 Android 的列名是不一样的，所以你需要使用 `CustomColumns.base` 、`CustomColumns.android` 或者 `CustomColumns.darwin` 去获取列名字。

```dart
PMFilter createFilter() {
  final CustomFilter filterOption = CustomFilter.sql(
    where: '${CustomColumns.base.width} > 100 AND ${CustomColumns.base.height} > 200',
    orderBy: [OrderByItem.desc(CustomColumns.base.createDate)],
  );

  return filterOption;
}
```

**更高级一些的** 过滤器


`class AdvancedCustomFilter extends CustomFilter`

[`AdvancedCustomFilter`] 是 [`CustomFilter`] 的子类，可以通过 builder 的方式去创建一个过滤器

```dart

PMFilter createFilter() {
  final group = WhereConditionGroup()
          .and(
            ColumnWhereCondition(
              column: CustomColumns.base.width,
              value: '100',
              operator: '>',
            ),
          )
          .or(
            ColumnWhereCondition(
              column: CustomColumns.base.height,
              value: '200',
              operator: '>',
            ),
          );

  final filter = AdvancedCustomFilter()
          .addWhereCondition(group)
          .addOrderBy(column: CustomColumns.base.createDate, isAsc: false);
  
  return filter;
}

```

**CustomFilter** 主要有以下几个类:

- `CustomFilter` : 自定义过滤器的基类
- `OrderByItem` :  能够实现排序的类. 
- `SqlCustomFilter` : `CustomFilter`的子类之一，通常用来构建出跟SQL一样的过滤器。
- `AdvancedCustomFilter`: `CustomFilter`的子类之一，能够构建更高级的过滤选项的过滤器。
  - `WhereConditionItem` : 条件抽象类.
    - `TextWhereCondition`:  文本过滤，用作不会被检查的文本。
    - `WhereConditionGroup` : 过滤组，用作创建一组条件。
    - `ColumnWhereCondition`: 列名过滤，表名次列将会被检查。
    - `DateColumnWhereCondition`: 日期过滤，由于iOS / macOS上的日期具有不同的转换方法，此实现可以平滑处理平台差异。
- `CustomColumns` : 自定义列，包含不同平台的字段。 
  - `base` : 基础列包含通用的字段，但请注意，在iOS上，“id”字段无效，甚至可能会导致错误。它只在Android上有效。
  - `android` : 适用于安卓的列。
  - `darwin` : 适用于iOS/macOS。

> PS: 需要注意的是，iOS使用 Photos API，而 Android使用 ContentProvider ，更接近 SQLite 。所以虽然它们被称为 “columns”，但这些字段实际上在 iOS/macOS 上是 PHAsset 字段，而在 Android 上则是 MediaStoreColumns 字段。

![flow_chart](flow_chart/advance_custom_filter.png)

#### 通过 `AssetPathEntity` 获取 `AssetEntity`

分页获取资源 [getAssetListPaged][`getAssetListPaged`]：

```dart
final List<AssetEntity> entities = await path.getAssetListPaged(page: 0, size: 80);
```

也可以获取范围 [getAssetListRange][`getAssetListRange`]：

```dart
final List<AssetEntity> entities = await path.getAssetListRange(start: 0, end: 80);
```

#### 通过 `PhotoManager` (Since 2.6.0) 获取 `AssetEntity`

首先，你可以获取 assets 的数量：

```dart
final int count = await PhotoManager.getAssetCount();
```

然后使用分页 [getAssetListPaged][`getAssetListPaged`] 获取：

```dart
final List<AssetEntity> entities = await PhotoManager.getAssetListPaged(page: 0, pageCount: 80);
```

或使用范围 [getAssetListRange][`getAssetListRange`] 获取：

```dart
final List<AssetEntity> entities = await PhotoManager.getAssetListRange(start: 0, end: 80);
```

**注意:**
`page`, `start` 都是从 0 开始。

#### 通过 ID 获取 `AssetEntity`

ID概念表示：

- 安卓上 `MediaStore` 的 `_id` 字段。
- iOS上为 `localIdentifier`，表示 `PHAsset` 的唯一标识。

如果您想要实现与持久选择相关的功能，可以存储 ID 。使用 [`AssetEntity.fromId`][] 在保留ID后检索Entity。

```dart
final AssetEntity? asset = await AssetEntity.fromId(id);
```

请注意，创建的资产可能具有有限的访问权限或在任何时候被删除，所以结果可能为空。

#### 通过 raw data 获取 `AssetEntity`


您可以从原始数据（如下载的图像、录制的视频等）创建自己的 `AssetEntity`。创建的 `AssetEntity` 将储存到设备的图库中。

```dart
final Uint8List rawData = yourRawData;

// 通过`Uint8List`作为一个Entity来保存一张图片 Save an image to an entity from `Uint8List`.
final AssetEntity? entity = await PhotoManager.editor.saveImage(
  rawData,
  title: 'write_your_own_title.jpg', // Affects EXIF reading.
);

// 通过路径来保存一张已存在的图片 Save an existed image to an entity from it's path.
final AssetEntity? imageEntityWithPath = await PhotoManager.editor.saveImageWithPath(
  path, //使用源文件的绝对路径来保存，其实和复制一样 Use the absolute path of your source file, it's more like a copy method.
  title: 'same_as_above.jpg',
);

// 通过`File`来保存视频 Save a video entity from `File`.
final File videoFile = File('path/to/your/video.mp4');
final AssetEntity? videoEntity = await PhotoManager.editor.saveVideo(
  videoFile, // 可以检查文件是否存在以获得更好的测试覆盖率 You can check whether the file is exist for better test coverage.
  title: 'write_your_own_title.mp4',
);

// [iOS only] 通过图片或者视频`File`来保存一张live photo。Save a live photo from image and video `File`.
// 只会在图片和视频文件为同一张live photo的时候才会生效。This only works when both image and video file were part of same live photo.
final File imageFile = File('path/to/your/livephoto.heic');
final File videoFile = File('path/to/your/livevideo.mp4');
final AssetEntity? entity = await PhotoManager.editor.darwin.saveLivePhoto(
  imageFile: imageFile,
  videoFile: videoFile,
  title: 'write_your_own_title.heic',
);
```

请注意，创建的Asset可能具有有限的访问权限或在任何时候被删除，所以结果可能为空。

#### 通过 iCloud

iOS中，为了节省磁盘空间，资源可能仅保存在iCloud上。
从iCloud检索文件时，速度取决于网络状况，可能非常缓慢，使用户感到焦虑。
为了提供响应灵敏的用户界面，您可以使用PMProgressHandler在加载文件时检索进度。


首选实现是 wechat_asset_picker 中的 [`LocallyAvailableBuilder`][]，它在下载文件时提供进度指示器。


#### Assets的显示

插件提供 [`AssetEntityImage`] 组件和 [`AssetEntityImageProvider`] 来显示Assets

```dart
final Widget image = AssetEntityImage(
  yourAssetEntity,
  isOriginal: false, // Defaults to `true`.
  thumbnailSize: const ThumbnailSize.square(200), // Preferred value.
  thumbnailFormat: ThumbnailFormat.jpeg, // Defaults to `jpeg`.
);

final Widget imageFromProvider = Image(
  image: AssetEntityImageProvider(
    yourAssetEntity,
    isOriginal: false,
    thumbnailSize: const ThumbnailSize.square(200),
    thumbnailFormat: ThumbnailFormat.jpeg,
  ),
);
```

#### 获取 "实况照片"

插件支持获取和过滤 live photos

##### 仅过滤“实况照片”

只在过滤图片的时候支持

```dart
final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
  type: RequestType.image,
  filterOption: FilterOptionGroup(onlyLivePhotos: true),
);
```

##### 通过“实况照片”来获取视频

```dart
final AssetEntity entity = livePhotoEntity;
final String? mediaUrl = await entity.getMediaUrl();
final File? imageFile = await entity.file;
final File? videoFile = await entity.fileWithSubtype;
final File? originImageFile = await entity.originFile;
final File? originVideoFile = await entity.originFileWithSubtype;
```

#### 限制

##### Android 10 媒体位置权限

由于 Android 10 上的隐私政策问题，为了获取带有位置信息和EXIF元数据的原始数据，必须授予位置权限。

如果你想使用位置权限，请将 `ACCESS_MEDIA_LOCATION` 权限添加到清单中。


##### 原始数据的使用

`originFile` 和 `originBytes` 的getter会返回实体的原始数据。
然而在Flutter中有一些情况下，原始数据是无效的。以下是一些常见的情况：

- 在多个平台上，HEIC文件不被完全支持。我们建议您上传JPEG文件（99％质量压缩的缩略图），
  以保持多个平台之间的一致行为。更多细节请参见[flutter/flutter＃20522][]。
- 视频将仅以原始格式获取，而不是导出/组合格式，
  这可能会在播放视频时导致某些行为差异。

##### iOS上文件检索时间过长

这个库中有几个针对 AssetEntity 的 I/O 方法，通常它们是：

- 所有名称为  `file`  的方法.
- `AssetEntity.originBytes`.

在 iOS 上，文件的检索和缓存受到沙盒机制的限制。
一个现有的 PHAsset 并不意味着该文件位于设备上。一般来说，一个 PHAsset 会有三种状态：

- `isLocallyAvailable` 等于 `true`, **并且已经缓存**: 可以获取。
- `isLocallyAvailable` 等于 `true`, **但没有缓存**: 当您调用 I/O 方法时， 资源将首先缓存在沙盒中，然后可以获取。
- `isLocallyAvailable` 等于 `false`: 通常这意味着该资源存在， 但仅保存在 iCloud 上，
  或者某些视频尚未导出。在这种情况下，最好使用 `PMProgressHandler` 提供响应迅速的用户界面。

### Entities change notify

插件将从原生广播实体变更的event，但它们将包含不同的内容。请参见[日志](log)文件夹以获取更多记录的日志。

要为这些事件注册回调，请使用 [`PhotoManager.addChangeCallback`] 添加回调，并使用 [`PhotoManager.removeChangeCallback`] 移除回调，就像 addListener 和 removeListener 方法一样。

在添加/移除回调之后，您可以调用[`PhotoManager.startChangeNotify`] 方法启用通知，以及 [`PhotoManager.stopChangeNotify`] 方法停止通知。


```dart
import 'package:flutter/services.dart';

void changeNotify(MethodCall call) {
  // Your custom callback.
}

/// Register your callback.
PhotoManager.addChangeCallback(changeNotify);

/// Enable change notify.
PhotoManager.startChangeNotify();

/// Remove your callback.
PhotoManager.removeChangeCallback(changeNotify);

/// Disable change notify.
PhotoManager.stopChangeNotify();
```

## 缓存机制

### Android缓存

由于Android 10限制了直接访问资源路径的能力，
因此图像缓存将在I/O处理过程中生成。
更具体地说，当调用 `file`，`originFile` 或任何 I/O 操作时，
插件将保存一个文件到缓存文件夹以供进一步使用。

幸运的是，在Android 11及以上版本中，可以再次直接获取资源路径，
在安卓 10 中，您仍然可以使用 `requestLegacyExternalStorage`
访问存储中的文件而不缓存它们。
有关如何添加属性，请参见 [Android 10+ (Q, 29)](#android-10--q-29-) for how to add the attribute.

### iOS缓存

iOS没有直接提供API来访问相册的原始文件。
因此，当调用 `file` , `originFile` 或任何 I/O 操作时，
将在当前应用程序的沙盒容器中生成一个缓存文件。

如果在您的用例中占用磁盘空间很敏感，
则可以在使用后删除它（仅适用于 iOS ）。

```dart
import 'dart:io';

Future<void> useEntity(AssetEntity entity) async {
  File? file;
  try {
    file = await entity.file;
    handleFile(file!); // Custom method to handle the obtained file.
  } finally {
    if (Platform.isIOS) {
      file?.deleteSync(); // Delete it once the process has done.
    }
  }
}
```

### 清除缓存

你可以使用 [`PhotoManager.clearFileCache`] 方法来清除插件生成的所有缓存。
这些缓存生成于不同平台、类型和分辨率等情况下。

| Platform | Thumbnail | File / Origin File |
| -------- | --------- | ------------------ |
| Android  | Yes       | No                 |
| iOS      | No        | Yes                |

## 原生额外配置

### 安卓额外配置

#### Glide issues

如果你发现与Glide存在任何版本冲突，那么需要编辑 `android/build.gradle` 文件：

```gradle
rootProject.allprojects {
    subprojects {
        project.configurations.all {
            resolutionStrategy.eachDependency { details ->
                if (details.requested.group == 'com.github.bumptech.glide'
                        && details.requested.name.contains('glide')) {
                    details.useVersion '4.14.2'
                }
            }
        }
    }
}
```

如果您想了解如何同时使用 ProGuard 和 Glide，详情请参阅 [ProGuard for Glide](https://github.com/bumptech/glide#proguard)。

#### Android 13 (API level 33) 额外配置

当目标为 Android 13 ( API level 33 ) 时，需要在清单文件中添加以下额外配置：

```xml
<manifest>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" /> <!-- If you want to read images-->
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" /> <!-- If you want to read videos-->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" /> <!-- If you want to read audio-->
</manifest>
```

### iOS额外配置

#### 本地化的系统相册名

默认情况下，iOS 只会以英语检索系统相册的名称，
无论设备上设置了什么语言。
要更改默认语言，请按照以下步骤操作：

- 用 Xcode 打开你的 iOS 项目 (Runner.xcworkspace)
![Edit localizations in Xcode 1](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/iosFlutterProjectEditinginXcode.png)

- 选择你项目的 “Runner”，在本地化表格中单击加号图标。
![Edit localizations in Xcode 2](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/iosFlutterAddLocalization.png)

- 选择您想要检索本地化的语言。
- 在不进行任何修改的情况下验证弹出屏幕。
- 重新构建您的 Flutter 项目。

现在系统相册的名称应该能够正确的显示。

### 实验性功能

**警告**: 此处的功能不能保证完全可用，
因为它们涉及到数据修改。
它们可能随时被修改/删除，
而不遵循适当的版本语义。

某些 API 将对数据进行不可逆的修改/删除。
**在使用这些功能时，请谨慎并实现自己的测试机制**.

#### 预加载缩略图

您可以使用 [`PhotoCachingManager.requestCacheAssets`][] 或 [`PhotoCachingManager.requestCacheAssetsWithIds`][] 方法来
针对具有指定缩略图选项的实体预加载缩略图。


```dart
PhotoCachingManager().requestCacheAssets(assets: assets, option: option);
```

您可以通过调用 [`PhotoCachingManager().cancelCacheRequest`][] 方法随时停止预加载。

通常，在预览资源时将使用缩略图。
但有时我们希望预加载资源以使其显示更快。

在 iOS 上使用 `PhotoCachingManager`，
在 Android 上使用 Glide 的文件缓存。

#### 删除 Entities

**此方法将从您的设备中完全删除资源,请谨慎使用。**

```dart
// Deleted IDs will returned, if it fails, the result will be an empty list.
final List<String> result = await PhotoManager.editor.deleteWithIds(
  <String>[entity.id],
);
```

删除后，您可以调用 `refreshPathProperties` 方法刷新相应的 `AssetPathEntity`
以便获取最新的字段。

#### 复制 Entity

您可以使用 `copyAssetToPath` 方法将实体“复制”到目标 `AssetPathEntity` 中：

```dart
// Make sure your path entity is accessible.
final AssetPathEntity anotherPathEntity = anotherAccessiblePath;
final AssetEntity entity = yourEntity;
final AssetEntity? newEntity = await PhotoManager.editor.copyAssetToPath(
  asset: entity,
  pathEntity: anotherPathEntity,
); // The result could be null when the path is not accessible.
```

“复制”在 Android 和 iOS 上的含义不同：

- 对于 Android，它会插入源Entity的副本：
  - 在平台 <=28 上，该方法将复制大部分来源信息。
  - 在平台 >=29 上，某些字段无法在插入期间修改， 如 [MediaColumns.RELATIVE_PATH][].
- 对于 iOS，它会创建一个快捷方式，而不是创建一个新的Entity。
  - 一些相册是智能相册，它们的内容由系统自动管理， 不能手动插入Entity。

（对于 Android 30+，由于系统限制，此功能当前被屏蔽。）

#### 仅适用于 Android 的功能

##### 将实体移动到另一个相册

```dart
// Make sure your path entity is accessible.
final AssetPathEntity pathEntity = accessiblePath;
final AssetEntity entity = yourEntity;
await PhotoManager.editor.android.moveAssetToAnother(
  entity: entity,
  target: pathEntity,
);
```

（对于 Android 30+，由于系统限制，此功能当前被屏蔽。）

##### 移除所有不存在的Entities

这将删除所有本地不存在的项目（记录）。
安卓的 `MediaStore` 中的记录对应的文件可能会被其他的 app 或文件管理器删除。
这些异常行为通常是由文件管理器、辅助工具或 adb 工具造成的。
此操作很消耗资源，`await` 结果返回前，请不要重复调用。

```dart
await PhotoManager.editor.android.removeAllNoExistsAsset();
```

某些系统将为每个 `AssetEntity` 的删除分别弹出确认对话框，
我们无法避免它们。
请确保你的客户接受反复确认。

#### 适用于 iOS 或 macOS 的功能

##### 创建一个文件夹

```dart
PhotoManager.editor.darwin.createFolder(
  name,
  parent: parent, // Null, the root path or accessible folders.
);
```

##### 创建一个相簿

```dart
PhotoManager.editor.darwin.createAlbum(
  name,
  parent: parent, // Null, the root path or accessible folders.
);
```

##### 从相册中删除 Entity

从特定相册中删除资产条目的条目。
该 Asset 不会从设备中删除，只会从相册中删除。

```dart
// 确保你的路径能够访问的 Make sure your path entity is accessible.
final AssetPathEntity pathEntity = accessiblePath;
final AssetEntity entity = yourEntity;
final List<AssetEntity> entities = <AssetEntity>[yourEntity, anotherEntity];
// 移除相簿的单个图片 Remove single asset from the album.
// 这将调用列表的方法作为实现。It'll call the list method as the implementation.
await PhotoManager.editor.darwin.removeInAlbum(
  yourEntity,
  accessiblePath,
);
// 批量从相册中移除资产。
await PhotoManager.editor.darwin.removeAssetsInAlbum(
  entities,
  accessiblePath,
);
```

##### 删除一个 `AssetPathEntity`

一些相簿无法删除。

```dart
PhotoManager.editor.darwin.deletePath();
```

[pub package]: https://pub.dev/packages/photo_manager
[repo]: https://github.com/fluttercandies/flutter_photo_manager
[GitHub issues]: https://github.com/fluttercandies/flutter_photo_manager/issues

[Glide]: https://bumptech.github.io/glide/
[Generated API]: https://bumptech.github.io/glide/doc/generatedapi.html
[MediaColumns.RELATIVE_PATH]: https://developer.android.com/reference/android/provider/MediaStore.MediaColumns#RELATIVE_PATH
[PHAuthorizationStatus]: https://developer.apple.com/documentation/photokit/phauthorizationstatus?language=objc
[PHCachingImageManager]: https://developer.apple.com/documentation/photokit/phcachingimagemanager?language=objc

[`AssetPathEntity`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/AssetPathEntity-class.html
[`AssetEntity`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/AssetEntity-class.html
[`getAssetPathList`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoManager/getAssetPathList.html
[`getAssetListPaged`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/AssetPathEntity/getAssetListPaged.html
[`getAssetListRange`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/AssetPathEntity/getAssetListRange.html
[`AssetEntity.fromId`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/AssetEntity/fromId.html
[`PhotoCachingManager.requestCacheAssets`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoCachingManager/requestCacheAssets.html
[`PhotoCachingManager.requestCacheAssetsWithIds`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoCachingManager/requestCacheAssetsWithIds.html
[`PhotoCachingManager().cancelCacheRequest`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoCachingManager/cancelCacheRequest.html
[`PhotoManager.addChangeCallback`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoManager/addChangeCallback.html
[`PhotoManager.startChangeNotify`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoManager/startChangeNotify.html
[`PhotoManager.stopChangeNotify`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoManager/stopChangeNotify.html
[`PhotoManager.clearFileCache`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoManager/clearFileCache.html
[`PhotoManager.requestPermissionExtend`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoManager/requestPermissionExtend.html
[`PermissionState`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PermissionState.html
[`PhotoManager.presentLimited`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/PhotoManager/presentLimited.html
[`CustomFilter`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/CustomFilter-class.html
[`AdvancedCustomFilter`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/AdvancedCustomFilter-class.html
[`SqlCustomFilter`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/SqlCustomFilter-class.html
[`AssetEntityImage`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/AssetEntityImage-class.html
[`AssetEntityImageProvider`]: https://pub.dev/documentation/photo_manager/latest/photo_manager/AssetEntityImageProvider-class.html


[`LocallyAvailableBuilder`]: https://github.com/fluttercandies/flutter_wechat_assets_picker/blob/2055adfa74370339d10e6f09adef72f2130d2380/lib/src/widget/builder/locally_available_builder.dart

[flutter/flutter#20522]: https://github.com/flutter/flutter/issues/20522
