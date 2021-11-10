# CHANGELOG

## 1.3.10
Improvements:
- Allow all kinds of `PHAssetCollection` which should expand the support for shared albums. (#641)

## 1.3.9+1
Fixes:
- Fix compile error on Xcode 12 for iOS 14. (#630)

## 1.3.9
Fixes:
- Fix `presentLimited` issues on iOS 14 real devices. (#627)

## 1.3.8
Improvements:
- Improve sort orders on all platforms. (#623)

## 1.3.7
Improvements:
- Improve sort orders on iOS. (#620)

## 1.3.6
Improvements:
- Prettify file name on iOS. (#615)

## 1.3.5
Improvements:
- Support `presentLimited` with the new API on iOS 15. (#609)

## 1.3.4

Improvements:
- Obtain more albums on iOS/macOS. (#601)

## 1.3.3

Improvements:
- Loosen comparison between `AssetEntity`s.

## 1.3.2

Improvements:
- Apply more fields to compare between entities.

## 1.3.1

Fixes:
- `fetchPathProperties` returned wrong `isAll` on iOS. (#580)
- `updateTimeCond` not constructed correctly with `FilterOptionGroup`.

## 1.3.0

Improvements:
- Repo cleanup.

Fixes:
- Removed recursive calls with progress handler. (#577)

We're bumping the minor version because we've achieved recent goals
and applied multiple Fixes: which make this plugin as the most solid ever.

## 1.2.9

Features:
- Add orientated getters. (#575)

## 1.2.8

Fixes:
- Saving methods return null. (#573)

## 1.2.7

Improvements:
- Improve `AssetEntity.getMediaUrl()` behaviors.

Fixes:
- Merge all fields for `FilterOptionGroup`.
- Make `AssetEntity.isLocallyAvailable` as a `Future` getter.

## 1.2.6+1

Fixes:
- Apply further fix to #559 .
- Repo cleanup.

## 1.2.6

Fixes:
- #558
- #559
- #560

## 1.2.5

Fixes:
- Fix `open` setting for macOS.
- Fix `setLog` for iOS and macOS.

## 1.2.4

Fixes:
- `saveImage` method missing file extension for the fallback title.
- `openSettings` method.

## 1.2.3

Fixes:
- Change notify issue on remove callback.
- Reply result for `presentLimited` method.

Feature:
- Add assets count change when notify on iOS.
- Add some properties and methods for change notify.

## 1.2.2

Fixes:
- Add request permissions result listener when activity re-attached. (#515)

## 1.2.1

Fixes:
- An error of iOS. See #509 and #510 .

## 1.2.0

Feature:
- Add requestPermissionExtend code to support iOS 14 permission.
- Add update limited photos method for iOS 14.

Fixes:
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

Fixes:
- `thumbWithSize` of `AssetEntity`.

## 1.1.0

Feature:
- `modified` of `AssetPathEntity`.
- Update constructor of `FilterOptionGroup`.

Fixes:
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

Breaking change:
- Migrate to null safety.
- Correct type in `PMRequestState` .

## 0.6.0

Feature
- Support android API 30.
- Support show empty album in iOS (#365).
- User can ignore check permission(User can choose favorite permission plugin,
  but at the same time user have to bear the risks corresponding to the permission).
- Support clean file cache.
- Experimental
  - Preload image (Use `PhotoCachingManager` api.)
- Add `OrderOption` as sort condition. The option default value is order by create date desc;
- Support icloud asset progress.
  
Fixes:
- #362
- Delete assets in androidQ.
- Edited image data in iOS.
- Fix delete error in androidR.

Breaking change:
- Support multiple sorting conditions, and the `asc` of `DateTimeCond` is removed.

## 0.5.8

Fixes:
- Delete assets in androidQ.

## 0.5.7

Fixes:
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

Fixes:
- Cannot get audio problem in androidQ.

## 0.5.2

- Support macOS.
- From the version, Starting from this version, 1.9 or earlier versions are not supported.

## 0.5.1

Feature:
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

Fixes:
- Problem of AssetPathEntity.refreshPathProperties.
- Open setting in iOS.
- Edited asset in iOS.
- Audio properties of FilterOption.
- Android onlyAll assetCount bug.

Change:
- Modified `AssetEntity.file`'s behavior on iOS,
  it will return a picture in jpg format instead of heic/gif/png currently.
  Now more in line with the description in the doc,
  this is suitable for uploading images (theoretically, no Exif information will be included).
- Update android change media url from file scheme to content scheme.
- Clean up some unused code.

## 0.5.0

Feature:
- Add `getSubPathEntities` for `AssetPathEntity`.
- Add `quality` for `AssetEntity.thumbDataWithSize`.
- Add `orientation` for `AssetEntity`.
- Add `onlyAll` for `getAssetPathList`.
- Support audio type(Only android, iOS Photos have no audio)
- **Breaking change**, Add date condition to filter datetime
  - Add class `DateTimeCond`
  - Add `dateTimeCond` to `FilterOptionGroup`
  - Remove `fetchDateTime` from `getAssetPathList`
  - Remove param `dt` from `AssetPathEntity.refreshPathProperties`, and add `refreshPathProperties` params to the method.

Update:
- **Breaking change**, Split video filter and image filter
- iOS code is running background thread.
- getThumb is running in background thread.

Fixes:
- exists error on android.
- use edited origin file on iOS.
- galleryName maybe is null in android.
- thumb of android 10.

## 0.4.8

Fixes:
- #169
- #170

## 0.4.7

New feature:
- Add `FilterOption` for method `getAssetPathList`.

## 0.4.6

Fixes:
- originFile of `AssetEntity`

Add:
- location(`latitude`,`longitude`) of `AssetEntity`
- `title` of `AssetEntity`
- `originBytes` of `AssetEntity`
- param `format` in `thumbDataWithSize` of assetEntity.

## 0.4.5

Fixes:
- Can't get thumb/file of video on androidQ.

## 0.4.4

Fixes:
- Compatibility code, when the width and height of the video is empty, it can still be scanned.
- Add a default value to `type` of `getAssetPathList`.

## 0.4.3

Add:
- Delete asset.
- Add Image.
- Add Video.
- Add modifyDate property.
- Fix videoDuration error.

Fixes:
- CreateDate error.

## 0.4.2

- Fix ios get full file size error.

## 0.4.1

- Fix ios build error.

## 0.4.0

Breaking change.
- Some properties in the entity were modified from asynchronous to synchronous.
- Remove `isCache` params. Now, `getAssetPathList` will reload info everytime.
  If user want to cache `List<AssetPathEntity>`, then user must do it manually.

Added:
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

- Support Android X.
- **Breaking change**: Migrate from the deprecated original Android Support Library to AndroidX.
  This shouldn't result in any functional changes,
  but it requires any Android apps using this plugin to also migrate if they're using the original support library.
- Fix NPE for image crash on android.
- Add a method to create `AssetEntity` with id.
- Add `isCache` for method `getImageAsset`,`getVideoAsset` or `getAssetPathList`.
- Add observer for photo change.
- Add field `createTime` for `AssetEntity`.

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
