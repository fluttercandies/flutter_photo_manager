# Migration Guide

The document only describes the equivalent changes to the API.
If you want to see the new feature support, please refer to [readme][] and [change log][].

<!-- TOC -->
* [Migration Guide](#migration-guide)
  * [3.x to 3.4](#3x-to-34)
    * [Overall](#overall)
      * [`saveLivePhoto`](#savelivephoto)
  * [3.x to 3.3](#3x-to-33)
    * [Overall](#overall-1)
      * [`saveImage`](#saveimage)
  * [3.0.x to 3.1](#30x-to-31)
    * [Overall](#overall-2)
      * [`containsLivePhotos`](#containslivephotos)
      * [`AlbumType`](#albumtype)
  * [2.x to 3.0](#2x-to-30)
    * [Overall](#overall-3)
      * [`AssetEntityImage` and `AssetEntityImageProvider`](#assetentityimage-and-assetentityimageprovider)
  * [2.x to 2.8](#2x-to-28)
    * [Overall](#overall-4)
  * [2.x to 2.2](#2x-to-22)
    * [Overall](#overall-5)
      * [`assetCount`](#assetcount)
  * [1.x to 2.0](#1x-to-20)
    * [Overall](#overall-6)
    * [API migrations](#api-migrations)
      * [`getAssetListPaged`](#getassetlistpaged)
      * [Filtering only videos](#filtering-only-videos)
      * [`isLocallyAvailable`](#islocallyavailable)
      * [iOS Editor favorite asset](#ios-editor-favorite-asset)
  * [0.6 to 1.0](#06-to-10)
  * [0.5 To 0.6](#05-to-06)
<!-- TOC -->

## 3.x to 3.4

### Overall

In order to let developers write the most precise API usage,
the `filename` of `saveLivePhoto` has migrated to `title`.

#### `saveLivePhoto`

Before:
```dart
final entity = await PhotoManager.editor.saveLivePhoto(
  imageFile: imageFile,
  videoFile: videoFile,
  filename: 'live_0',
);
```

After:
```dart
final entity = await PhotoManager.editor.saveLivePhoto(
  imageFile: imageFile,
  videoFile: videoFile,
  title: 'live_0',
);
```

## 3.x to 3.3

### Overall

In order to let developers write the most precise API usage,
the `title` of `saveImage` has migrated to `filename`.

#### `saveImage`

Before:
```dart
final entity = await PhotoManager.editor.saveImage(bytes, title: 'new.jpg');
```

After:
```dart
final entity = await PhotoManager.editor.saveImage(bytes, filename: 'new.jpg');
```

## 3.0.x to 3.1

### Overall

- `containsLivePhotos` now defaults to `false` instead of `true`.
- `AssetPathEntity.darwinType` and `AssetPathEntity.darwinSubtype` are deprecated.

#### `containsLivePhotos`

Live Photos are used to being obtained when querying images and videos, the behavior sometimes causes drama that users don't want to see images when getting videos. The flag is now disabled by default.

#### `AlbumType`

The extra information of the album type has been abstract as `AlbumType`
which contains Darwin (iOS/macOS) and OpenHarmony album information.
The new class deprecates `AssetPathEntity.darwinType` and `AssetPathEntity.darwinSubtype`,
`AssetPathEntity.albumTypeEx` should be used instead.

Before:

```dart
final path = await AssetPathEntity.fromId('');
final PMDarwinAssetCollectionType? darwinType = path.darwinType;
final PMDarwinAssetCollectionSubtype? darwinSubtype = path.darwinSubtype;
```

After: 

```dart
final path = await AssetPathEntity.fromId('');
final PMDarwinAssetCollectionType? darwinType = path.albumTypeEx?.darwin?.type;
final PMDarwinAssetCollectionSubtype? darwinSubtype = path.albumTypeEx?.darwin?.subtype;
```

## 2.x to 3.0

### Overall

- Use `Editor.darwin` instead of `Editor.iOS`.
- Use `PermissionRequestOption` instead of `PermisstionRequestOption`.
- Use `AssetPathEntity.assetCountAsync` instead of `AssetPathEntity.assetCount`.
- Removed `AssetEntityImage` and `AssetEntityImageProvider`.

#### `AssetEntityImage` and `AssetEntityImageProvider`

These classes are no longer provided from the package.
Instead, include
[photo_manager_image_provider](https://pub.dev/packages/photo_manager_image_provider/install)
to use `AssetEntityImage` and `AssetEntityImageProvider`.

```dart
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
```

## 2.x to 2.8

### Overall

Methods invoked with assets permission no longer call for permissions implicitly.
Users must follow the below methods to ensure permissions were granted:

1. `PhotoManager.requestPermissionExtend()`, verify if the result is
   `authorized` or `limited`.
2. `PhotoManager.setIgnorePermissionCheck(true)`, ignoring permission checks,
   or handle permissions with other mechanisms.

`PhotoManager.editor.deleteWithIds` only move assets to the trash on Android 30 and above.

## 2.x to 2.2

### Overall

- `AssetPathEntity.assetCount` has been deprecated, and added a new asynchronized getter `assetCountAsync`.
- `FilterOptionGroup.containsEmptyAlbum` has been removed.

#### `assetCount`

Before you can easily access total count of a path:

```dart
int get count => path.assetCount;
```

Now you can only use the new getter:

```dart
int count = await path.assetCountAsync;
```

Be aware that the change is to improve when gathering info from paths,
which means usages with the previous field should be migrated to
separate requests to improve the performance.

## 1.x to 2.0

This version mainly covers all valid issues, API deprecations, and few new features.

### Overall

- The org name has been updated from `top.kikt` to `com.fluttercandies`.
- The plugin name on native side has been updated from `ImageScanner` to `PhotoManager`.
- `AssetPathEntity` and `AssetEntity` are now immutable.
- `title` are required when using saving methods.
- `RequestType.common` is the default type for all type request.
- Arguments with `getAssetListPaged` are now required with name.
- `PhotoManager.notifyingOfChange` has no setter anymore.
- `PhotoManager.refreshAssetProperties` and `PhotoManager.fetchPathProperties` have been moved to entities.
- `containsLivePhotos` are `true` by default.
  If you previously used `RequestType.video` to filter assets, they'll include live photos now.
  To keep to old behavior, you should explicitly set `containsLivePhotos` to `false` in this case.
- `isLocallyAvailable` now passes `isOrigin`, so it's been changed to `isLocallyAvailable()`.

### API migrations

There are several APIs have been removed, since they can't provide precise meanings, or can be replaced by new APIs.
If you've used these APIs, consider migrating them to the latest version.

| Removed API/class/field                 | Migrate destination                                      |
|:----------------------------------------|:---------------------------------------------------------|
| `PhotoManager.getImageAsset`            | `PhotoManager.getAssetPathList(type: RequestType.image)` |
| `PhotoManager.getVideoAsset`            | `PhotoManager.getAssetPathList(type: RequestType.video)` |
| `PhotoManager.fetchPathProperties`      | `AssetPathEntity.fetchPathProperties`                    |
| `PhotoManager.refreshAssetProperties`   | `AssetEntity.refreshProperties`                          |
| `PhotoManager.requestPermission`        | `PhotoManager.requestPermissionExtend`                   |
| `AssetPathEntity.assetList`             | N/A, use pagination APIs instead.                        |
| `AssetPathEntity.refreshPathProperties` | `AssetPathEntity.obtainForNewProperties`                 |
| `AssetEntity.createDtSecond`            | `AssetEntity.createDateSecond`                           |
| `AssetEntity.fullData`                  | `AssetEntity.originBytes`                                |
| `AssetEntity.thumbData`                 | `AssetEntity.thumbnailData`                              |
| `AssetEntity.refreshProperties`         | `AssetEntity.obtainForNewProperties`                     |
| `FilterOptionGroup.dateTimeCond`        | `FilterOptionGroup.createTimeCond`                       |
| `ThumbFormat`                           | `ThumbnailFormat`                                        |
| `ThumbOption`                           | `ThumbnailOption`                                        |

#### `getAssetListPaged`

Before:

```dart
AssetPathEntity.getAssetListPaged(0, 50);
```

After:

```dart
AssetPathEntity.getAssetListPaged(page: 0, size: 50);
```

#### Filtering only videos

Before:

```dart
final List<AssetPathEntity> paths = PhotoManager.getAssetPathList(type: RequestType.video);
```

After:

```dart
final List<AssetPathEntity> paths = PhotoManager.getAssetPathList(
  type: RequestType.video,
  filterOption: FilterOptionGroup(containsLivePhotos: false),
);
```

#### `isLocallyAvailable`

Before:

```dart
final bool isLocallyAvailable = await entity.isLocallyAvailable;
```

After:

```dart
// .file is locally available.
final bool isFileLocallyAvailable = await entity.isLocallyAvailable();

// .originFile is locally available.
final bool isOriginFileLocallyAvailable = await entity.isLocallyAvailable(
  isOrigin: true,
);
```

#### iOS Editor favorite asset

Before:

```dart
final bool isSucceed = await PhotoManager.editor.darwin.favoriteAsset(
  entity: entity,
  favorite: true,
);
```

After:

```dart
/// If succeed, a new entity will be returned.
final AssetEntity? newEntity = await PhotoManager.editor.darwin.favoriteAsset(
  entity: entity,
  favorite: true,
);
```

## 0.6 to 1.0

This version is a null-safety version.

Please read document for null-safety information in [dart][dart-safe] or [flutter][flutter-safe].

[flutter-safe]: https://flutter.cn/docs/null-safety
[dart-safe]: https://dart.cn/null-safety

## 0.5 To 0.6

Before:

```dart
final dtCond = DateTimeCond(
  min: startDt,
  max: endDt,
  asc: asc,
)..dateTimeCond = dtCond;
```

After:

```dart
final dtCond = DateTimeCond(
  min: startDt,
  max: endDt,
);

final orderOption = OrderOption(
  type: OrderOptionType.createDate,
  asc: asc,
);

final filterOptionGroup = FilterOptionGroup()..addOrderOption(orderOption);
```

[readme]: ./README.md
[change log]: ./CHANGELOG.md
