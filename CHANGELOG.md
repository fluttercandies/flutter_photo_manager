<!-- Copyright 2018 The FlutterCandies author. All rights reserved.
Use of this source code is governed by an Apache license
that can be found in the LICENSE file. -->

# CHANGELOG

## 2.8.0

### Feature

- Support android API 34(Android 14) limit access to photos and videos.
- Because limit permission, we refactor the permission request API.

***Breaking changes for permission behavior***

Methods do not implicitly call for permission requests anymore.
User must follow the below methods to ensure permissions were granted:

1. `PhotoManager.requestPermissionExtend()`, verify if the result is
   `PermissionState.authorized` or `PermissionState.limited`.
2. `PhotoManager.setIgnorePermissionCheck(true)`, ignoring permission checks,
   handle permission with other mechanisms.

### Fixes

- Correct the key when fetching video info with MMR on Android. (#997)
- Retrieve original media instead of one with adjustments/filters for subtype files on iOS. (#976)
- Returns original file name instead of `FullSizeRender.*` if this has adjustments on iOS. (#976)

### Improvements

- Add locks to the image provider.

## 2.7.1

### Fixes

- Fix namespace on Android.
- Remove the package definition from the manifest.
- Use `math.pow(2^63)-1` to make Web compile work again.
- Fix the `end` argument of `PhotoManager.getAssetListRange` is being handled incorrectly on Darwin. (#962)

## 2.7.0

### Features

- Support `darwinType` and `darwinSubType` in `AssetPathEntity` on iOS and macOS. (#950)

### Improvements

- Roll dependencies on Android. (#933)

### Fixes

- Fix filter option group. (#919)
- Fix `originFileWithSubtype` and `fileWithSubtype` for livePhoto.
- Fix: support only add permission for iOS/macOS. (#944)
- Fix: modified the output path for iOS(add id in next path).
- Fix: Fixed a possible problem with the permission for darwin.
- Fix: `needTitle` for `CustomFilter`.

## 2.6.0

### Features

- Support `CustomFilter` for more filter options. (#901)
- Add two new static methods for `PhotoManager`:
  - `getAssetCount` for getting assets count.
  - `getAssetListRange` for getting assets between start and end.

## 2.5.2

### Improvements

- Reply errors when thumbnails are failed to load on Android. (#883)

## 2.5.1+1

### Fixes

- Fix pending permissions request on Android. (#879)

## 2.5.1

### Improvements

- Always declare `READ_EXTERNAL_STORAGE` permission on Android. (#874)
- Upgrade Glide and Kotlin libraries version. (#872)
- Avoid using file-based saving methods on Android. (#871)
- Use `ContentUris` for retrieving Media URIs on Android. (#870)
- Improve media subtype on iOS. (#863)

## 2.5.0

### Features

- Support saving Live Photos on iOS and macOS. (#851)
- Introduce `DarwinEditor` to replace `IosEditor`. (#855)

## 2.4.2

### Improvements

- Expose `frame` for `AssetEntity.thumbnailDataWithSize`. (#850)

## 2.4.1

### Improvements

- Use last modified date for Glide caches key on Android. (#848)

## 2.4.0

### Features

- Support both legacy and scoped storage on Android. (#833)

### Fixes

- Avoid duplicate `copyItemAtURL` for videos on iOS. (#840)
- Correct permission checks with `requestPermissionExtend` on Android 13. (#843)

## 2.3.0

### Features

- Support Android 13 (API 33) permissions.

### Improvements

- Adapt Flutter 3.3. (#820)
- Retrieve metadata for videos when empty on Android. (#819)

### Fixes

- Fix saving videos with path on Android 29-. (#829)

## 2.2.1

### Fixes

- Fix saving images with path on Android 29-. (#815)

## 2.2.0

### Breaking changes

- Introduce `AssetPathEntity.assetCountAsync` getter,
  which improves the speed when loading paths mainly on iOS, also:
  - Deprecate `AssetPathEntity.assetCount`.
  - Remove `FilterOptionGroup.containsEmptyAlbum`.

### Improvements

- Improve assets change notify with better methods signature and checks. (#790)
- Add `PermissionState.hasAccess` getter for better condition judgement. (#792)
- Remove unnecessary assets fetch in `getMediaUrl` on iOS. (#793)
- Improve `AssetEntity.obtainForNewProperties` on iOS. (#794)
- Improve `MD5Utils` on iOS. (#802)
- Improve cache container mutations on iOS. (#803)
- Improve assets count assignments. (#804)
- Improve cursors conversion on Android. (#806)

### Fixes

- Purpose video creation correctly on iOS. (#791)
- Mark assets as favorite on iOS. (#794)
- Fix not replied method calls (#800).
- Fix invalid `RELATIVE_PATH` obtains with cursors on Android Q-. (#810)

## 2.1.4

### Improvements

- [iOS] Check `canPerformEditOperation` before performing change requests. (#782)

### Fixes

- [Android] Fix `orientation` missing during conversions. (#783)

## 2.1.3

### Improvements

- Expose `PhotoManager.plugin`. (#778)

### Fixes

- Fix `forceOldApi` not well-called. (#778)
- Fix invalid type cast with `AssetEntity.exists`. (#777)

## 2.1.2

### Improvements

- Correct `PermissionRequestOption` typo with a class type alias.
  Which also raised the Dart SDK constraint to `2.13.0`.
- Catch throwables when reading EXIF.
- Improve Live-Photos filtering.

## 2.1.1

### Improvements

- Protect cursors convert on Android. (#761)
- Present exceptions in the image provider when debugging. (#766)

### Fixes

- Fix `ACCESS_MEDIA_LOCATION` checks on Android. (#765)

## 2.1.0+2

### Improvements

- Support Flutter 3.

## 2.0.9

### Improvements

- (Not working) Ignore the null-aware operator for
  `PaintingBinding`'s instance in order to solve
  the coming lint issues with Flutter 2.13,
  and keeps the compatibility of previous Flutter versions.
- Fix dart docs generate issues.

## 2.0.8

### Improvements

- Using `ContentResolver` as much as possible on Android. (#755)

## 2.0.7

### Fixes

- Fix assets pagination issues on Android 29+. (#748)

## 2.0.6

### Fixes

- Fix file caches clearing on iOS. (#743)

## 2.0.5

### Improvements

- Improve `AssetEntity.titleAsync`'s implementation on iOS. (#740)

## 2.0.4

### Fixes

- Fix invalid `InputStream` when saving images on Android. (#736)

## 2.0.3

### Improvements

- Improve `getMediaUrl` on iOS.
- Read orientation when saving images on Android. (#730)
- Improve generic type casts on Android. (#732)

## 2.0.2

### Fixes

- Ensure file exists before reading EXIF on Android. (#728)

## 2.0.1

### Improvements

- Update legacy external storage exception on Android.

### Fixes

- Predicate more precise permissions requirements on Android <29. (#723)

## 2.0.0

A major version release for performance improvements, new features, issues fixed, and breaking changes.
Also, the LICENSE has been updated with the new author [FlutterCandies](https://github.com/fluttercandies).
To know more about breaking changes, see the [Migration Guide][].

### Features

- Add `mimeTypeAsync`. (#717)
- Add `ThumbnailSize`. (#709)
- Add `DurationConstraint.allowNullable`. (#681)
- Introduce `AssetEntityImageProvider`. (#669, #709)
- Support "Live Photos" with obtaining and filtering. (#667, #670, #673, #719)
- Support to obtain the first frame for the video thumbnail on Android. (#658)
- Allow plugin to be mocked/overridden with tests. (#703)

### Improvements

- Improve path modified injection and asset count fetching. (#712)
- Make all entities immutable. (#708)
- Improve the performance when using the `file` getter on iOS. (#705)
- Force legacy storage on Android Q. (#701)
- Enhance request types filtering.
- Compile for API 31 on Android.
- Throw when obtaining media URL that asset is not locally available on iOS.
- Retrieve width/height from ExifInterface for fallback on Android. (#686)
- Request `WRITE_EXTERNAL_STORAGE` only when needed. (#675)
- Provided a single-page example. (#672)
- Improve the default sort order on all platforms. (#659)
- Add equality comparison for various classes. (#657)
- Run Glide on the current thread on Android. (#656)
- Improve thread pool on Android. (#637)
- Improved all documents and code formats. (#626, #660, #664, #671)
- Reorganized all internal structures.
- Rename org to `com.fluttercandies`. (#624)
- `ImageScanner` -> `PhotoManager`. (#611)

### Fixes

- Fix `Activity` leaks when detached on Android. (#716)
- Fix potential NPE when moving assets on Android.
- Fix edited images/videos are not returned correctly on iOS. (#622, #636)
- Fix `title` argument causes saving methods failed. (#619, #635)
- Fix `PhotoManager.editor.copyAssetToPath` returns `null`. (#619)
- Fix sort order issues on iOS/macOS. (#603, #655)

## 1.3.10

### Improvements

- Allow all kinds of `PHAssetCollection` which should expand the support for shared albums. (#641)

## 1.3.9+1

### Fixes

- Fix compile error on Xcode 12 for iOS 14. (#630)

## 1.3.9

### Fixes

- Fix `presentLimited` issues on iOS 14 real devices. (#627)

## 1.3.8

### Improvements

- Improve sort orders on all platforms. (#623)

## 1.3.7

### Improvements

- Improve sort orders on iOS. (#620)

## 1.3.6

### Improvements

- Prettify file name on iOS. (#615)

## 1.3.5

### Improvements

- Support `presentLimited` with the new API on iOS 15. (#609)

## 1.3.4

### Improvements

- Obtain more albums on iOS/macOS. (#601)

## 1.3.3

### Improvements

- Loosen comparison between `AssetEntity`s.

## 1.3.2

### Improvements

- Apply more fields to compare between entities.

## 1.3.1

### Fixes

- `fetchPathProperties` returned wrong `isAll` on iOS. (#580)
- `updateTimeCond` not constructed correctly with `FilterOptionGroup`.

## 1.3.0

### Improvements

- Repo cleanup.

### Fixes

- Removed recursive calls with progress handler. (#577)

We're bumping the minor version because we've achieved recent goals
and applied multiple ### Fixes which make this plugin as the most solid ever.

## 1.2.9

### Features

- Add orientated getters. (#575)

## 1.2.8

### Fixes

- Saving methods return null. (#573)

## 1.2.7

### Improvements

- Improve `AssetEntity.getMediaUrl()` behaviors.

### Fixes

- Merge all fields for `FilterOptionGroup`.
- Make `AssetEntity.isLocallyAvailable` as a `Future` getter.

## 1.2.6+1

### Fixes

- Apply further fix to #559 .
- Repo cleanup.

## 1.2.6

### Fixes

- #558
- #559
- #560

## 1.2.5

### Fixes

- Fix `open` setting for macOS.
- Fix `setLog` for iOS and macOS.

## 1.2.4

### Fixes

- `saveImage` method missing file extension for the fallback title.
- `openSettings` method.

## 1.2.3

### Features

- Add assets count change when notify on iOS.
- Add some properties and methods for change notify.

### Fixes

- Change notify issue on remove callback.
- Reply result for `presentLimited` method.

## 1.2.2

### Fixes

- Add request permissions result listener when activity re-attached. (#515)

## 1.2.1

### Fixes

- An error of iOS. See #509 and #510 .

## 1.2.0

### Features

- Add `requestPermissionExtend` code to support iOS 14 permission.
- Add update limited photos method for iOS 14.

### Fixes

- Permissions dialog of launch on old iOS versions. (#503)

## 1.1.6

- The `MEDIA_LOCATION` permission of android can be removed through configuration.

## 1.1.5

- Revert #478 .
- Fix thumbnail size of the entity on iOS/macOS.

## 1.1.4

- Merged #478 .

## 1.1.3

- Merged the code of macOS and ios.

## 1.1.2

- Updated the code in the macOS part.

## 1.1.1

### Fixes

- `thumbWithSize` of `AssetEntity`.

## 1.1.0

### Features

- `modified` of `AssetPathEntity`.
- Update constructor of `FilterOptionGroup`.

### Fixes

- Order option of the `FilterOptionGroup`.

## 1.0.6

- Add relative path when saving files to the MediaStore on Android 29+ (#462)
- Fix deleteWithIds typecast issue with Android 29- (#460)

## 1.0.4

- Add mime type for android.

## 1.0.3

- Fix serious code usage issue in convert utils.

## 1.0.2

- Improve the constructor for `AssetEntity`.

## 1.0.1

- Fix orientation bug.

## 1.0.0

### Breaking changes

- Migrate to null safety.
- Correct type in `PMRequestState` .

## 0.6.0

### Breaking changes

- Support multiple sorting conditions, and the `asc` of `DateTimeCond` is removed.

### Features

- Support android API 30.
- Support show empty album in iOS (#365).
- User can ignore check permission(User can choose favorite permission plugin,
  but at the same time user have to bear the risks corresponding to the permission).
- Support clean file cache.
- Experimental
  - Preload image (Use `PhotoCachingManager` api.)
- Add `OrderOption` as sort condition. The option default value is order by create date desc;
- Support icloud asset progress.

### Fixes

- #362
- Delete assets in androidQ.
- Edited image data in iOS.
- Fix delete error in androidR.

## 0.5.8

### Fixes

- Delete assets in androidQ.

## 0.5.7

### Fixes

- Audio asset error for androidQ. See #340 and #341 .

## 0.5.6

- Fix save image with path for android.

## 0.5.5+1

- Remove verbose log.

## 0.5.5

- Add `merge` for `FilterOptionGroup` and `FilterOption` .

## 0.5.4

- Add `copyWith` for `FilterOption` .

## 0.5.3+1

- Support android v2 model.

## 0.5.3

### Fixes

- Cannot get audio problem in androidQ.

## 0.5.2

- Support macOS.
- From the version, Starting from this version, 1.9 or earlier versions are not supported.

## 0.5.1

### Features

- Save image asset with file path.
- Copy asset to another album.
- Create AssetEntity with id.
- Create AssetPathEntity from id.
- Only iOS
  - Create folder or album.
  - Remove assets in album.
  - Delete folder or album.
  - Favorite asset.
- Only android
  - move asset to another path.
  - Remove all non-existing rows.
  - add `relativePath` for android.

### Improvements

- Modified `AssetEntity.file`'s behavior on iOS,
  it will return a picture in jpg format instead of heic/gif/png currently.
  Now more in line with the description in the doc,
  this is suitable for uploading images (theoretically, no Exif information will be included).
- Update android change media url from file scheme to content scheme.
- Clean up some unused code.

### Fixes

- Problem of AssetPathEntity.refreshPathProperties.
- Open setting in iOS.
- Edited asset in iOS.
- Audio properties of FilterOption.
- Android onlyAll assetCount bug.

## 0.5.0

### Breaking changes

- Add date condition to filter datetime
- Add class `DateTimeCond`
- Add `dateTimeCond` to `FilterOptionGroup`
- Remove `fetchDateTime` from `getAssetPathList`
- Remove param `dt` from `AssetPathEntity.refreshPathProperties`,
  and add `refreshPathProperties` params to the method.
- Split video filter and image filter.

### Features

- Add `getSubPathEntities` for `AssetPathEntity`.
- Add `quality` for `AssetEntity.thumbDataWithSize`.
- Add `orientation` for `AssetEntity`.
- Add `onlyAll` for `getAssetPathList`.
- Support audio type(Only android, iOS Photos have no audio)

### Improvements

- iOS code is running background thread.
- getThumb is running in background thread.

### Fixes

- exists error on android.
- use edited origin file on iOS.
- galleryName maybe is null in android.
- thumb of android 10.

## 0.4.8

### Fixes

- #169
- #170

## 0.4.7

### Features

- Add `FilterOption` for method `getAssetPathList`.

## 0.4.6

### Fixes

- originFile of `AssetEntity`

### Features

- location(`latitude`,`longitude`) of `AssetEntity`
- `title` of `AssetEntity`
- `originBytes` of `AssetEntity`
- param `format` in `thumbDataWithSize` of assetEntity.

## 0.4.5

### Fixes

- Can't get thumb/file of video on androidQ.

## 0.4.4

### Fixes

- Compatibility code, when the width and height of the video is empty, it can still be scanned.
- Add a default value to `type` of `getAssetPathList`.

## 0.4.3

### Features

- Delete asset.
- Add Image.
- Add Video.
- Add modifyDate property.
- Fix videoDuration error.

### Fixes

- CreateDate error.

## 0.4.2

- Fix ios get full file size error.

## 0.4.1

- Fix ios build error.

## 0.4.0

### Breaking changes

- Some properties in the entity were modified from asynchronous to synchronous.
- Remove `isCache` params. Now, `getAssetPathList` will reload info everytime.
  If user want to cache `List<AssetPathEntity>`, then user must do it manually.

### Features

- Added a method `getAssetListPaged` for paging loading resources to path.
  The paging implementation is lazy loading, that is, the resource corresponding information is loaded when requested.
  The entity corresponding to the path is no longer placed in the memory,
  but is implemented by PHPhoto (ios) and sqlite's limit offset (android).
- Support AndroidQ privacy.

## 0.3.5

- Fix iCloud image problem.

## 0.3.4

- Support flutter 1.6.0 android's thread changes for channel.

## 0.3.3

- Fix customizing album containing folders on iOS.

## 0.3.2

- `AssetEntity` add property: `originFile`.

## 0.3.1

- `AssetEntity` add property: `exists`.

## 0.3.0

### Breaking changes

- Support Android X.
  This shouldn't result in any functional changes,
  but it requires any Android apps using this plugin to also migrate
  if they're using the original support library.

### Features

- Add a method to create `AssetEntity` with id.
- Add `isCache` for method `getImageAsset`,`getVideoAsset` or `getAssetPathList`.
- Add observer for photo change.
- Add field `createTime` for `AssetEntity`.

### Fixes

- Fix NPE for image crash on android.

## 0.2.1

- Add `getVideoAsset` and `getImageAsset` to load video / image.

## 0.2.0

- Add asset size field.
- Add cache release method.

## 0.1.10

- Fix when number of photo/video is 0, will crash.

## 0.1.9

- Add video duration.

## 0.1.8

- Sort asset by date.

## 0.1.7

- Fix Android's latest picture won't be found.
- Update gradle wrapper version.
- Update kotlin version.

## 0.1.6

- Fix Android to get pictures that are empty bug.

## 0.1.5

- Support ios icloud image and video.

## 0.1.4

- Update all path `hasVideo` property.

## 0.1.3

- Add a params to help user disable get video.

## 0.1.2

- iOS get video file is async.

## 0.1.1

- Fix 'ios video full file is a jpg' problem.

## 0.1.0

- Support video in android.
- Change API from ImageXXXX to AssetXXXX.

## 0.0.3

- Update for the issue #1. (NPE when request other permission on android)

## 0.0.2

- Update README.

## 0.0.1

First version.

- API for photo.

[Migration Guide]: MIGRATION_GUIDE.md
