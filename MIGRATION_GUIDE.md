# Migration Guide

The document only describes the equivalent changes to the API.
If you want to see the new feature support, please refer to [readme][] and [change log][].

- [Migration Guide](#migration-guide)
  - [2.x to 3.0](#2x-to-30)
    - [Overall](#overall)
      - [AssetEntityImage and AssetEntityImageProvider](#assetentityimage-and-assetentityimageprovider)
  - [2.x to 2.2](#2x-to-22)
    - [Overall](#overall-1)
      - [`assetCount`](#assetcount)
  - [1.x to 2.0](#1x-to-20)
    - [Overall](#overall-2)
    - [API migrations](#api-migrations)
      - [`getAssetListPaged`](#getassetlistpaged)
      - [Filtering only videos](#filtering-only-videos)
      - [`isLocallyAvailable`](#islocallyavailable)
      - [iOS Editor favorite asset](#ios-editor-favorite-asset)
  - [0.6 to 1.0](#06-to-10)
  - [0.5 To 0.6](#05-to-06)

## 2.x to 3.0

### Overall

- `Editor.iOS`: use `Editor.darwin` instead.
- `PermisstionRequestOption`: use `PermissionRequestOption` instead.
- `AssetPathEntity.assetCount`: use `AssetPathEntity.assetCountAsync` instead.
- Removed `AssetEntityImage` and `AssetEntityImageProvider`.

#### AssetEntityImage and AssetEntityImageProvider

You just include [photo_manager_image_provider](https://pub.dev/packages/photo_manager_image_provider/install) in your project.

If you use the flutter 3.14.0 or higher, use 2.x version, otherwise use 1.x version.

`flutter pub add photo_manager_image_provider:^2.1.0`
`flutter pub add photo_manager_image_provider:^1.1.0`

```dart
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
```

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
