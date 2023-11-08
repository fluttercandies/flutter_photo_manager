<!-- Copyright 2018 The FlutterCandies author. All rights reserved.
Use of this source code is governed by an Apache license
that can be found in the LICENSE file. -->

# photo_manager

[English](README.md) | 中文

[![pub package](https://img.shields.io/pub/v/photo_manager?label=%E7%A8%B3%E5%AE%9A%E7%89%88)][pub package]
[![pub pre-release package](https://img.shields.io/pub/v/photo_manager?color=9d00ff&include_prereleases&label=%E6%B5%8B%E8%AF%95%E7%89%88)][pub package]
[![Build status](https://img.shields.io/github/actions/workflow/status/fluttercandies/flutter_photo_manager/runnable.yml?branch=main&label=CI&logo=github&style=flat-square)](https://github.com/fluttercandies/flutter_photo_manager/actions/workflows/runnable.yml)
[![GitHub license](https://img.shields.io/github/license/fluttercandies/flutter_photo_manager)](https://github.com/fluttercandies/flutter_photo_manager/blob/main/LICENSE)

[![GitHub stars](https://img.shields.io/github/stars/fluttercandies/flutter_photo_manager?style=social&label=Stars)](https://github.com/fluttercandies/flutter_photo_manager/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/fluttercandies/flutter_photo_manager?logo=github&style=flat-square)](https://github.com/fluttercandies/flutter_photo_manager/network)
[![Awesome Flutter](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/Solido/awesome-flutter)
<a target="_blank" href="https://jq.qq.com/?_wv=1027&k=5bcc0gy"><img border="0" src="https://pub.idqqimg.com/wpa/images/group.png" alt="FlutterCandies" title="FlutterCandies"></a>

通过相册的抽象 API 对设备中的资源（图片、视频、音频）进行管理，不需要集成 UI。
在 Android、iOS 和 macOS 上可用。

## 集成此插件的推荐项目

| name                 | pub                                                                                                                          | github                                                                                                                                                                  |
|:---------------------|:-----------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| wechat_assets_picker | [![pub package](https://img.shields.io/pub/v/wechat_assets_picker)](https://pub.flutter-io.cn/packages/wechat_assets_picker) | [![star](https://img.shields.io/github/stars/fluttercandies/flutter_wechat_assets_picker?style=social)](https://github.com/fluttercandies/flutter_wechat_assets_picker) |
| wechat_camera_picker | [![pub package](https://img.shields.io/pub/v/wechat_camera_picker)](https://pub.flutter-io.cn/packages/wechat_camera_picker) | [![star](https://img.shields.io/github/stars/fluttercandies/flutter_wechat_camera_picker?style=social)](https://github.com/fluttercandies/flutter_wechat_camera_picker) |

## 关于此插件的文章

- [Hard to manage media with Flutter? Try photo_manager, the all-in-one solution](https://medium.flutter.cn/hard-to-manage-media-with-flutter-try-photo-manager-the-all-in-one-solution-5188599e4cf)

## 破坏性改动迁移指南

查看 [迁移指南](MIGRATION_GUIDE.md) 了解如何在破坏性改动之间迁移。

<details>
  <summary>目录列表</summary>

<!-- TOC -->
* [photo_manager](#photomanager)
  * [集成此插件的推荐项目](#集成此插件的推荐项目)
  * [关于此插件的文章](#关于此插件的文章)
  * [破坏性改动迁移指南](#破坏性改动迁移指南)
  * [常见问题](#常见问题)
  * [使用前准备](#使用前准备)
    * [添加依赖](#添加依赖)
    * [导入到你的项目中：](#导入到你的项目中)
    * [原生平台的配置](#原生平台的配置)
      * [Android 配置准备](#android-配置准备)
        * [Kotlin, Gradle, AGP](#kotlin-gradle-agp)
        * [Android 10 (Q, 29)](#android-10-q-29)
        * [Glide](#glide)
      * [iOS 配置准备](#ios-配置准备)
  * [使用方法](#使用方法)
    * [请求权限](#请求权限)
      * [受限的资源权限](#受限的资源权限)
        * [iOS 受限的资源权限](#ios-受限的资源权限)
        * [Android 受限的资源权限](#android-受限的资源权限)
    * [获取相簿或图集 (`AssetPathEntity`)](#获取相簿或图集-assetpathentity)
      * [`getAssetPathList` 方法的参数](#getassetpathlist-方法的参数)
      * [PMPathFilterOption](#pmpathfilteroption)
    * [获取资源 (`AssetEntity`)](#获取资源-assetentity)
      * [通过 `AssetPathEntity` 获取](#通过-assetpathentity-获取)
      * [通过 `PhotoManager` 方法 (2.6.0+) 获取](#通过-photomanager-方法-260-获取)
      * [通过 ID 获取](#通过-id-获取)
      * [通过原始数据获取](#通过原始数据获取)
      * [通过 iCloud 获取](#通过-icloud-获取)
      * [展示资源](#展示资源)
      * [获取「实况照片」](#获取实况照片)
        * [仅过滤「实况照片」](#仅过滤实况照片)
        * [获取「实况照片」的视频](#获取实况照片的视频)
      * [限制](#限制)
        * [Android 10 媒体位置权限](#android-10-媒体位置权限)
        * [原始数据的使用](#原始数据的使用)
        * [iOS 上文件检索时间过长](#ios-上文件检索时间过长)
    * [资源变动的通知回调](#资源变动的通知回调)
  * [过滤资源](#过滤资源)
    * [FilterOptionGroup](#filteroptiongroup)
    * [CustomFilter](#customfilter)
      * [更高级的 CustomFilter](#更高级的-customfilter)
      * [相关类定义解释](#相关类定义解释)
  * [缓存机制](#缓存机制)
    * [Android 缓存](#android-缓存)
    * [iOS 缓存](#ios-缓存)
    * [清除缓存](#清除缓存)
  * [原生额外配置](#原生额外配置)
    * [Android 额外配置](#android-额外配置)
      * [Glide 相关问题](#glide-相关问题)
      * [Android 14 (API level 34) 额外配置](#android-14-api-level-34-额外配置)
      * [Android 13 (API level 33) 额外配置](#android-13-api-level-33-额外配置)
    * [iOS 额外配置](#ios-额外配置)
      * [配置系统相册名称的国际化](#配置系统相册名称的国际化)
    * [实验性功能](#实验性功能)
      * [预加载缩略图](#预加载缩略图)
      * [删除资源](#删除资源)
      * [复制资源](#复制资源)
      * [仅适用于 Android 的功能](#仅适用于-android-的功能)
        * [将资源移动到另一个相册](#将资源移动到另一个相册)
        * [移除所有不存在的资源](#移除所有不存在的资源)
      * [适用于 iOS 或 macOS 的功能](#适用于-ios-或-macos-的功能)
        * [创建一个文件夹](#创建一个文件夹)
        * [创建一个相簿](#创建一个相簿)
        * [从相册中移除资源](#从相册中移除资源)
        * [删除 `AssetPathEntity`](#删除-assetpathentity)
<!-- TOC -->

</details>

## 常见问题

你可以在 [GitHub issues][] 上搜索到经常遇到的问题，比如构建错误，运行时异常等等。

## 使用前准备

### 添加依赖

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

- Android：[Android 配置准备](#android-配置准备).
- iOS：[iOS 配置准备](#ios-配置准备).
- macOS：与 iOS 几乎一致。

#### Android 配置准备

##### Kotlin, Gradle, AGP

该插件使用 **Kotlin `1.7.22`** 来构建。
如果你的项目使用了低于此版本的 Kotlin/Gradle/AGP，请升级到大于或等于指定版本。

更具体的做法:

- 更新你的 Gradle version (`gradle-wrapper.properties`)
  到 `7.5.1` 或者最新版本。
- 更新你的 Kotlin version (`ext.kotlin_version`)
  到 `1.7.22` 或者最新版本。
- 更新你的 AGP version (`com.android.tools.build:gradle`)
  或者 `7.2.2` 或者最新版本。

##### Android 10 (Q, 29)

_如果你没有设置 `compileSdkVersion` 或 `targetSdkVersion` 为 `29`，你可以跳过本节。_

Android 10 引入了 **Scoped Storage**，导致原始资源文件不能通过其文件路径直接访问。

如果你的 `compileSdkVersion` 或 `targetSdkVersion` 为 29,
为了能够成功获取到媒体资源，你可以考虑通过在 `AndroidManifest.xml`
中添加 `android:requestLegacyExternalStorage="true"`，如下所示:

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

**注意: 这样设置的应用无法上架 Google Play。**

这不是必须的，插件缓存文件的时候还是可以正常工作的。
但是开发者需要主动清理缓存，最佳实践是启动应用时调用
`PhotoManager.clearFileCache` 清理缓存文件。

##### Glide

本插件使用 [Glide][] 在 Android 平台上创建缩略图。

如果你发现 [Glide][] 出现了一些警告日志，说明主项目需要实现 `AppGlideModule`。
请查看 [Generated API][] 的相关文档说明。

#### iOS 配置准备

添加 `NSPhotoLibraryUsageDescription` 到你的项目的 `ios/Runner/Info.plist` 中：

```plist
<key>NSPhotoLibraryUsageDescription</key>
<string>In order to access your photo library</string>
```

在 iOS 11 或者更高版本中，如果你只需要请求相册的写入权限，
仅需要添加 `NSPhotoLibraryAddUsageDescription` 到你的项目的 `ios/Runner/Info.plist`。

![permissions in Xcode](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/flutter_photo2.png)

## 使用方法

### 请求权限

大部分的 API 只在获取到权限后才能正常使用。

```dart
final PermissionState ps = await PhotoManager.requestPermissionExtend();
if (ps.isAuth) {
  // 已获取到权限
} else if (ps.hasAccess) {
  // 已获取到权限（哪怕只是有限的访问权限）。
  // iOS Android 目前都已经有了部分权限的概念。
} else {
  // 权限受限制（iOS）或者被拒绝，使用 `==` 能够更准确的判断是受限还是拒绝。
  // 你可以使用 `PhotoManager.openSetting()` 打开系统设置页面进行进一步的逻辑定制。
}
```

如果你确定你的应用已经授予了权限，你也可以忽略权限的检查：
```dart
PhotoManager.setIgnorePermissionCheck(true);
```

对于一些后台操作（应用未启动等）而言，忽略检查是比较合适的做法。

#### 受限的资源权限

##### iOS 受限的资源权限

iOS14 引入了部分资源限制的权限 (`PermissionState.limited`)。
`PhotoManager.requestPermissionExtend()` 会返回当前的权限状态 `PermissionState`。
详情请参阅 [PHAuthorizationStatus][]。

如果你想要重新选择在应用里能够读取到的资源，你可以使用 `PhotoManager.presentLimited()` 重新选择资源，
这个方法对于 iOS 14 以上的版本生效。

##### Android 受限的资源权限

与 iOS 类似，Android 14 (API 34) 中也引入了这个概念。
它们在行为上略有不同（基于模拟器）：
在 Android 中一旦授予某个资源的访问权限，就无法撤销，
即使再次使用 `presentLimited` 时不选中也不会撤销对它的访问权限。

### 获取相簿或图集 (`AssetPathEntity`)

相簿或者图集以抽象类 [`AssetPathEntity`][] 的形式呈现，
在 Android 中它表示为具有相同 `bucketId` 的 `MediaStore` 记录的集合，
在 iOS/macOS 中则是 `PHAssetCollection` 的记录。

获取所有相册：
```dart
final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();
```

详情请参阅 [`getAssetPathList`][]。

#### `getAssetPathList` 方法的参数

| 参数名           | 说明                                                         | 默认值              |
| :--------------- | ------------------------------------------------------------ | ------------------- |
| hasAll           | 如果你需要一个包含所有资源（AssetEntity) 的 PathEntity ，传入 true | true                |
| onlyAll          | 如果你只需要一个包含所有资源的，传入true                     | false               |
| type             | 资源文件的类型（视频、图片、音频）                           | RequestType.common  |
| filterOption     | 用于筛选 AssetEntity，详情请参阅 [过滤资源](#过滤资源)       | FilterOptionGroup() |
| pathFilterOption | 只对 iOS 和 macOS生效，对应原生中的相册类型，详情请参阅 [PMPathFilterOption](#pmpathfilteroption)。 | 默认为包含所有      |

#### PMPathFilterOption

自 2.7.0 版本开始提供，当前仅支持 iOS 和 macOS。

```dart
final List<PMDarwinAssetCollectionType> pathTypeList = []; // 配置为你需要的类型
final List<PMDarwinAssetCollectionSubtype> pathSubTypeList = []; // 配置为你需要的子类型
final darwinPathFilterOption = PMDarwinPathFilter(
      type: pathTypeList,
      subType: pathSubTypeList,
    );
PMPathFilter pathFilter = PMPathFilter();
```

 `PMDarwinAssetCollectionType`的枚举值一一对应 [PHAssetCollectionType | 苹果官网文档](https://developer.apple.com/documentation/photokit/phassetcollectiontype?language=objc).

 `PMDarwinAssetCollectionSubtype` 的枚举值一一对应 [PHAssetCollectionSubType | 苹果官网文档](https://developer.apple.com/documentation/photokit/phassetcollectionsubtype?language=objc).

### 获取资源 (`AssetEntity`)

资源（图片/视频/音频）以 [`AssetEntity`][] 的方式呈现，
它抽象了原生中关于媒体对象的一系列属性和方法。
在 Android 中表示 `MediaStore` 记录的其中一些字段的集合，
在 iOS/macOS 则是 `PHAsset` 的记录。

#### 通过 `AssetPathEntity` 获取

你可以通过 [分页方法][`getAssetListPaged`] 获取：
```dart
final List<AssetEntity> entities = await path.getAssetListPaged(page: 0, size: 80);
```

也可以通过 [范围索引方法][`getAssetListRange`] 获取：
```dart
final List<AssetEntity> entities = await path.getAssetListRange(start: 0, end: 80);
```

#### 通过 `PhotoManager` 方法 (2.6.0+) 获取

首先你需要获取资源的数量：
```dart
final int count = await PhotoManager.getAssetCount();
```

然后通过 [分页方法][`PhotoManager.getAssetListPaged`] 获取：

```dart
final List<AssetEntity> entities = await PhotoManager.getAssetListPaged(page: 0, pageCount: 80);
```

也通过 [范围索引方法][`PhotoManager.getAssetListRange`] 获取：
```dart
final List<AssetEntity> entities = await PhotoManager.getAssetListRange(start: 0, end: 80);
```

**注意：** `page` 和`start` 都从 **0** 开始。

#### 通过 ID 获取

ID 在不同平台代表：

- Android 平台 `MediaStore` 的 `_id` 字段；
- iOS/macOS 平台 `PHAsset` 的 `localIdentifier` 字段。

如果你想要实现持久化选择的相关功能，你需要存储资源的 ID，
并在之后的使用中通过 [`AssetEntity.fromId`][]` 来重新持有资源对象。
```dart
final AssetEntity? asset = await AssetEntity.fromId(id);
```

请留意资源可能访问受限，或随时被删除，所以结果可能为空。

#### 通过原始数据获取

你可以从原始数据或文件（如下载的图像、录制的视频等）创建 `AssetEntity`。
创建的 `AssetEntity` 将储存到设备的图库中。
```dart
final Uint8List rawData = yourRawData;

// 将 `Uint8List` 保存为一张图片。
final AssetEntity? entity = await PhotoManager.editor.saveImage(
  rawData,
  title: 'write_your_own_title.jpg', // 可能影响 EXIF 信息的读取
);

// 通过路径来保存一张已存在的图片。
final AssetEntity? imageEntityWithPath = await PhotoManager.editor.saveImageWithPath(
  path, // 使用源文件的绝对路径来保存，与复制类似。
  title: 'same_as_above.jpg',
);

// 通过文件来保存视频。
final File videoFile = File('path/to/your/video.mp4');
final AssetEntity? videoEntity = await PhotoManager.editor.saveVideo(
  videoFile, // 可以检查文件是否存在以获得更好的测试覆盖率。
  title: 'write_your_own_title.mp4',
);

// [仅 iOS] 通过图片和视频来保存一张实况照片。
// 仅在图片和视频文件为同一张实况照片时才能生效。
final File imageFile = File('path/to/your/livephoto.heic');
final File videoFile = File('path/to/your/livevideo.mp4');
final AssetEntity? entity = await PhotoManager.editor.darwin.saveLivePhoto(
  imageFile: imageFile,
  videoFile: videoFile,
  title: 'write_your_own_title.heic',
);
```

请留意资源可能访问受限，或随时被删除，所以结果可能为空。

#### 通过 iCloud 获取

iOS 为了节省磁盘空间，可能将资源仅保存在 iCloud 上。
从 iCloud 检索资源文件时，速度会取决于网络状况，可能非常缓慢，使用户感到焦虑。
你可以使用 `PMProgressHandler` 在加载文件时提示用户当前的进度。

推荐参考的实践是 `wechat_asset_picker` 中的
[`LocallyAvailableBuilder`][]，它会在下载文件时提供进度的展示。

#### 展示资源

插件提供 `AssetEntityImage` widget 和
`AssetEntityImageProvider` 来处理资源的展示：
```dart
final Widget image = AssetEntityImage(
  yourAssetEntity,
  isOriginal: false,
  thumbnailSize: const ThumbnailSize.square(200),
  thumbnailFormat: ThumbnailFormat.jpeg,
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

#### 获取「实况照片」

该插件支持获取和过滤 iOS 上的实况照片。

##### 仅过滤「实况照片」

只在过滤图片的时候支持过滤「实况照片」：
```dart
final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
  type: RequestType.image,
  filterOption: FilterOptionGroup(onlyLivePhotos: true),
);
```

##### 获取「实况照片」的视频

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

在 Android 10 版本中获取带有位置信息和 EXIF 元数据的原始数据时，必须授予媒体位置权限。
若需要获取，请将 `ACCESS_MEDIA_LOCATION` 权限添加到清单中。

##### 原始数据的使用

`originFile` 和 `originBytes` 的 getter 会返回资源的原始数据。
然而在 Flutter 中，某些情况的原始数据是无法使用的。以下是一些常见的情况：

- 在不同平台和版本中，HEIC 文件并未被完全支持。
  我们建议你上传 JPEG 文件（HEIC 图片的 `.file`），
  以保持多个平台之间的一致行为。
  查看 [flutter/flutter＃20522][] 了解更多细节。
- 视频将仅以原始格式获取，而不是组合过的格式，
  这可能会在播放视频时导致某些行为的差异。

##### iOS 上文件检索时间过长

该插件中有几个针对 `AssetEntity` 的 I/O 方法：

- 所有名称带有 `file` 的方法.
- `AssetEntity.originBytes`.

在 iOS 上，文件的检索和缓存受到沙盒机制的限制。
能获取到 `PHAsset` 并不意味着该资源位于设备上。
一般来说，`PHAsset` 会有三种状态：

- `isLocallyAvailable` 等于 `true`, **并且已经缓存**：可以获取。
- `isLocallyAvailable` 等于 `true`, **但没有缓存**：当你调用 I/O 方法时，资源需要缓存在沙盒中才可以获取。
- `isLocallyAvailable` 等于 `false`，通常意味着资源仅保存在 iCloud 上，或者某些视频尚未导出过。
  在这种情况下，最好使用 `PMProgressHandler` 提供响应式的用户界面。

### 资源变动的通知回调

插件会从原生平台广播资源变更的事件，但是在不同的平台和系统版本之间，事件携带的内容并不相同。
你可以参考 [相关日志](log) 了解各个版本和平台之间的事件日志。

要为这些事件注册回调，请使用 `PhotoManager.addChangeCallback` 添加回调，
并使用 `PhotoManager.removeChangeCallback` 移除回调，
与 `addListener` 和 `removeListener` 方法相似。

在添加/移除回调之后，你可以调用 [`PhotoManager.startChangeNotify` 方法启用通知，
以及 `PhotoManager.stopChangeNotify` 方法停止通知。

```dart
import 'package:flutter/services.dart';

void changeNotify(MethodCall call) {
  // 你的自定义回调。
}

/// 注册你的回调方法。
PhotoManager.addChangeCallback(changeNotify);

/// 启用事件通知订阅。
PhotoManager.startChangeNotify();

/// 移除你的回调方法。
PhotoManager.removeChangeCallback(changeNotify);

/// 取消事件通知订阅。
PhotoManager.stopChangeNotify();
```

## 过滤资源

插件包含对资源过滤筛选的支持。
以下的方法包含 `filterOption` 参数，用于指定资源过滤的条件。
- PhotoManager
  - getAssetPathList（可以通过 `AssetPathEntity.filterOption` 获取）
  - getAssetCount
  - getAssetListRange
  - getAssetListPaged
- AssetPathEntity
  - 构造（不推荐直接使用）
  - fromId
  - obtainPathFromProperties（不推荐直接使用）

插件支持两种形式的资源筛选：
- [FilterOptionGroup](#FilterOptionGroup)
- [CustomFilter](#CustomFilter)

### FilterOptionGroup

`FilterOptionGroup` 是 2.6.0 版本前唯一支持的筛选器实现。

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
  /// 其他选项
);
```

### CustomFilter

**注意：** `CustomFilter` 自 v2.6.0 引入。由于其存在时间较短，无法保证其稳定性。
如果在使用时遇到相关问题，请按照模板提交 issue。

`CustomFilter` 针对不同平台提供了更加灵活的筛选条件。
其使用方法更像平台本身的处理方法，即类 SQL 的筛选方式。

SQL 筛选的字段名称在不同平台上是不一致的，
在使用时请注意区分 `CustomColumns.base`、`CustomColumns.android` 以及 `CustomColumns.darwin`
来获取正确的字段名称。

构造一个 `CustomFilter` 的例子：
```dart
CustomFilter createFilter() {
  return CustomFilter.sql(
    where: '${CustomColumns.base.width} > 100 AND ${CustomColumns.base.height} > 200',
    orderBy: [OrderByItem.desc(CustomColumns.base.createDate)],
  );
}
```

#### 更高级的 CustomFilter

`AdvancedCustomFilter` 继承自 `CustomFilter`，
可以通过 builder 方式创建一个筛选器。

```dart
CustomFilter createFilter() {
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

#### 相关类定义解释

- `CustomFilter`：自定义筛选器的基类。
- `SqlCustomFilter`：类 SQL 的筛选器。
- `AdvancedCustomFilter`：构建自定义选项的筛选器。
  - `OrderByItem`：实现排序的类，功能类似于 ORDER BY。
  - `WhereConditionItem`：条件筛选的抽象类，功能类似于 WHERE。
    - `WhereConditionGroup`：筛选条件组，将一组条件合并在同一个条件组。
    - `TextWhereCondition`：字符串筛选条件，在传递时不会检查是否有效。
    - `ColumnWhereCondition`：字段名筛选条件，在传递时会检查字段名是否有效。
    - `DateColumnWhereCondition`：日期筛选条件，由于 iOS/macOS 上的日期格式不同，该条件可以帮助处理这些差异。
- `CustomColumns`：不同平台的字段名。
  - `base`：适用于各个平台通用的字段名，但在 iOS 上 "id" 字段无效，甚至可能会导致错误。它只在 Android 上有效。
  - `android`：适用于 Android 的字段名。
  - `darwin`：适用于 iOS/macOS 的字段名。

下图为自定义筛选器作用的流程图：
![flow_chart](flow_chart/advance_custom_filter.png)

## 缓存机制

### Android 缓存

由于 Android 10 限制了直接访问资源路径的能力，
因此图像缓存将在 I/O 处理过程中生成。
更具体地说，当调用 `file`，`originFile` 或任何 I/O 操作时，
插件将保存一个文件到缓存文件夹以供进一步使用。

幸运的是，在 Android 11 及以上版本中，可以再次直接获取资源路径，
在 Android 10 中，你仍然可以使用 `requestLegacyExternalStorage`
访问存储中的文件而不缓存它们。
有关如何添加属性，请参见 [Android 10 (Q, 29)](#android-10-q-29)。
该属性不是必需的。

### iOS 缓存

iOS 没有直接提供 API 来访问相册资源的原始文件。
因此，当调用 `file`、`originFile` 或相关的文件操作时，
将在当前应用程序的沙盒中生成对应的缓存文件。

如果在你的用例中占用磁盘空间很敏感，
那么你可以在使用完成后删除它（仅适用于 iOS）。

```dart
import 'dart:io';

Future<void> useEntity(AssetEntity entity) async {
  File? file;
  try {
    file = await entity.file;
    await handleFile(file!); // 处理获取的文件
  } finally {
    if (Platform.isIOS) {
      file?.deleteSync(); // 处理完成后删除
    }
  }
}
```

### 清除缓存

你可以使用 `PhotoManager.clearFileCache` 方法来清除插件生成的所有缓存。
缓存的生成取决于不同平台、类型和分辨率等情况。

| 平台      | 缩略图 | 文件 / 原始文件        |
|---------|-----|------------------|
| Android | 生成  | 生成 (Android 10+) |
| iOS     | 不生成 | 生成               |

## 原生额外配置

### Android 额外配置

#### Glide 相关问题

如果你的项目存在 Glide 的版本冲突问题，
那么你需要编辑 `android/build.gradle` 文件：

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

如果你想了解如何同时使用 ProGuard 和 Glide，请参阅
[ProGuard for Glide](https://github.com/bumptech/glide#proguard)。

#### Android 14 (API level 34) 额外配置

当应用的 `targetSdkVersion` 为 34 (Android 14) 时，
你需要在清单文件中添加以下额外配置：

```xml
<manifest>
   <uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" /> <!-- 这是一个可选的配置，不指定并不影响在代码中使用它 -->
</manifest>
```

#### Android 13 (API level 33) 额外配置

当应用的 `targetSdkVersion` 为 33 (Android 13) 时，
你需要在清单文件中添加以下额外配置：

```xml
<manifest>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" /> <!-- 如果需要读取图片 -->
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" /> <!-- 如果需要读取视频 -->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" /> <!-- 如果需要读取音频 -->
</manifest>
```

### iOS 额外配置

#### 配置系统相册名称的国际化

默认情况下，无论设备上设置了什么语言，iOS 都只会以英语检索系统相册的名称。
要更改默认语言，请按照以下步骤操作：

- 用 Xcode 打开你的 iOS 项目 (Runner.xcworkspace)
![Edit localizations in Xcode 1](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/iosFlutterProjectEditinginXcode.png)

- 选择你项目的 “Runner”，在本地化表格中单击加号图标。
![Edit localizations in Xcode 2](https://raw.githubusercontent.com/CaiJingLong/some_asset/master/iosFlutterAddLocalization.png)

- 选择你想要检索本地化的语言。
- 在不进行任何修改的情况下验证弹出屏幕。
- 重新构建你的 Flutter 项目。

现在系统相册的名称应该能够以对应的语言显示。

**注意**: 本地化相册名称不代表自定义。

### 实验性功能

**警告**: 此处的功能不能保证在所有平台和系统版本下完全可用，
因为它们涉及到数据修改。
它们可能在任何版本中随时被修改或删除。

某些 API 将对数据进行不可逆的修改和删除。
**在使用这些功能时，请谨慎操作，并最好实现先行测试**。

#### 预加载缩略图

你可以使用 `PhotoCachingManager.requestCacheAssets`
或 `PhotoCachingManager.requestCacheAssetsWithIds` 方法
以特定的缩略图选项来加载部分资源的缩略图。

```dart
PhotoCachingManager().requestCacheAssets(assets: assets, option: option);
```

你也可以通过调用
`PhotoCachingManager().cancelCacheRequest`
方法随时停止预加载。

通常在 app 预览资源时，会使用缩略图进行展示。
但有时我们希望预加载资源以使其显示更快。

`PhotoCachingManager` 在 iOS 上使用的是 [PHCachingImageManager][]，
在 Android 上使用 Glide 的文件缓存。

#### 删除资源

**此方法将从你的图库中完全删除资源，请谨慎使用。**

```dart
// 调用方法会返回被删除的资源，如果全部失败会返回空列表。
final List<String> result = await PhotoManager.editor.deleteWithIds(
  <String>[entity.id],
);
```

删除后，你可以调用 `refreshPathProperties` 方法刷新相应的
`AssetPathEntity` 以便更新字段。

#### 复制资源

你可以使用 `copyAssetToPath` 方法将资源 “复制” 到目标 `AssetPathEntity` 中：

```dart
// 确保 anotherPathEntity 对于当前 app 而言可以访问。
final AssetPathEntity anotherPathEntity = anotherAccessiblePath;
final AssetEntity entity = yourEntity;
final AssetEntity? newEntity = await PhotoManager.editor.copyAssetToPath(
  asset: entity,
  pathEntity: anotherPathEntity,
); // 如果 anotherPathEntity 无法访问，结果会返回 null。
```

“复制” 在 Android 和 iOS 上有不同的含义：

- 对于 Android，它会插入源资源的副本：
  - 在 SDK <= 28 上，该方法将复制大部分来源信息。
  - 在 SDK >= 29 上，某些字段无法在插入期间修改，如 [MediaColumns.RELATIVE_PATH][].
- 对于 iOS，它会创建一个快捷方式，而不是创建一个新的资源。
  - 某些相册是智能相册，它们的内容由系统自动管理，不能手动插入资源。

（对于 Android 30+，由于系统限制，此功能当前被屏蔽。）

#### 仅适用于 Android 的功能

##### 将资源移动到另一个相册

```dart
// 确保 accessiblePath 对于当前 app 而言可以访问。
final AssetPathEntity pathEntity = accessiblePath;
final AssetEntity entity = yourEntity;
await PhotoManager.editor.android.moveAssetToAnother(
  entity: entity,
  target: pathEntity,
);
```

（对于 Android 30+，由于系统限制，此功能当前被屏蔽。）

##### 将资源移动到废纸篓

```dart
await PhotoManager.editor.android.moveToTrash(list);
```

这个方法用于将资源移动到废纸篓，它仅支持安卓 API 30+，低于 30 的 API 会抛出异常。

##### 移除所有不存在的资源

这将删除所有本地不存在的相册条目。
安卓的 `MediaStore` 中的记录对应的文件可能会被其他的 app 或文件管理器删除。
这些异常行为通常是由文件管理器、辅助工具或 adb 工具造成的。
此操作很消耗资源，请不要重复调用。

```dart
await PhotoManager.editor.android.removeAllNoExistsAsset();
```

某些系统会在每个资源删除时分别弹出确认对话框，这是无法避免的。
请确认你需要调用该方法，并且你的客户接受反复弹窗确认。

#### 适用于 iOS 或 macOS 的功能

##### 创建一个文件夹

```dart
PhotoManager.editor.darwin.createFolder(
  name,
  parent: parent, // 应为 null、根目录或者其他可访问的文件夹
);
```

##### 创建一个相簿

```dart
PhotoManager.editor.darwin.createAlbum(
  name,
  parent: parent, // 应为 null、根目录或者其他可访问的文件夹
);
```

##### 从相册中移除资源

从特定相册中移除资源。
该移除不会从设备中删除，只会从相册中被移除。

```dart
// 确保你的路径能够访问。
final AssetPathEntity pathEntity = accessiblePath;
final AssetEntity entity = yourEntity;
final List<AssetEntity> entities = <AssetEntity>[yourEntity, anotherEntity];
// 移除相簿的单个图片
// 这将调用列表移除的方法作为实现。
await PhotoManager.editor.darwin.removeInAlbum(
  yourEntity,
  accessiblePath,
);
// 批量从相册中移除资源。
await PhotoManager.editor.darwin.removeAssetsInAlbum(
  entities,
  accessiblePath,
);
```

##### 删除 `AssetPathEntity`

智能相册无法被删除。

```dart
PhotoManager.editor.darwin.deletePath();
```

[pub package]: https://pub.flutter-io.cn/packages/photo_manager
[repo]: https://github.com/fluttercandies/flutter_photo_manager
[GitHub issues]: https://github.com/fluttercandies/flutter_photo_manager/issues

[Glide]: https://muyangmin.github.io/glide-docs-cn/
[Generated API]: https://muyangmin.github.io/glide-docs-cn/doc/generatedapi.html
[MediaColumns.RELATIVE_PATH]: https://developer.android.com/reference/android/provider/MediaStore.MediaColumns#RELATIVE_PATH
[PHAuthorizationStatus]: https://developer.apple.com/documentation/photokit/phauthorizationstatus?language=objc
[PHCachingImageManager]: https://developer.apple.com/documentation/photokit/phcachingimagemanager?language=objc

[`AssetPathEntity`]: https://pub.flutter-io.cn/documentation/photo_manager/latest/photo_manager/AssetPathEntity-class.html
[`AssetEntity`]: https://pub.flutter-io.cn/documentation/photo_manager/latest/photo_manager/AssetEntity-class.html
[`getAssetPathList`]: https://pub.flutter-io.cn/documentation/photo_manager/latest/photo_manager/PhotoManager/getAssetPathList.html
[`getAssetListPaged`]: https://pub.flutter-io.cn/documentation/photo_manager/latest/photo_manager/AssetPathEntity/getAssetListPaged.html
[`getAssetListRange`]: https://pub.flutter-io.cn/documentation/photo_manager/latest/photo_manager/AssetPathEntity/getAssetListRange.html
[`PhotoManager.getAssetListPaged`]: https://pub.flutter-io.cn/documentation/photo_manager/latest/photo_manager/PhotoManager/getAssetListPaged.html
[`PhotoManager.getAssetListRange`]: https://pub.flutter-io.cn/documentation/photo_manager/latest/photo_manager/PhotoManager/getAssetListRange.html
[`AssetEntity.fromId`]: https://pub.flutter-io.cn/documentation/photo_manager/latest/photo_manager/AssetEntity/fromId.html

[`LocallyAvailableBuilder`]: https://github.com/fluttercandies/flutter_wechat_assets_picker/blob/2055adfa74370339d10e6f09adef72f2130d2380/lib/src/widget/builder/locally_available_builder.dart

[flutter/flutter#20522]: https://github.com/flutter/flutter/issues/20522
