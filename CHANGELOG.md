# CHANGELOG

## 0.4.0

Breaking change.

- Some properties in the entity were modified from asynchronous to synchronous.
- Remove `isCache` params. Now, `getAssetPathList` will reload info everytime. If user want to cache `List<AssetPathEntity>`, then user must do it self.

Added:

- Added a method `getAssetListPaged` for paging loading resources to path. The paging implementation is lazy loading, that is, the resource corresponding information is loaded when requested. The entity corresponding to the path is no longer placed in the memory, but is implemented by PHPhoto (ios) and sqlite's limit offset (android).
- Support AndroidQ privacy.

## 0.3.5

Fix

- ICloud image problem.

## 0.3.4

Support flutter 1.6.0 android's thread changes for channel.

## 0.3.3

Fix customizing album containing folders on iOS.

## 0.3.2

`AssetEntity` add property: `originFile`

## 0.3.1

`AssetEntity` add property: `exists`

## 0.3.0

- Support Android X.
- **Breaking change**. Migrate from the deprecated original Android Support Library to AndroidX. This shouldn't result in any functional changes, but it requires any Android apps using this plugin to also migrate if they're using the original support library.

fix NPE for image crash on android.

add a method to create `AssetEntity` with id

add `isCache` for method `getImageAsset`,`getVideoAsset` or `getAssetPathList`

add observer for photo change.

add field `createTime` for `AssetEntity`

## 0.2.1

add two method to load video / image

`getVideoAsset` `getImageAsset`

## 0.2.0

add asset size field

release cache method

## 0.1.10

fix

    when number of photo/video is 0, will crash

## 0.1.9

add video duration

## 0.1.8 sort asset by data

## 0.1.7 fix bug

fix bug: Android's latest picture won't be found

update gradle wrapper version.

update kotlin version

## 0.1.6

Fix Android to get pictures that are empty bug.

## 0.1.5

support ios icloud image and video

## 0.1.4 fix bug

update all path hasVideo property

## 0.1.3 add params

add a params to help user disable get video

## 0.1.2 fix bug

ios get video file is async

## 0.1.1 fix ios video

fix 'ios video full file is a jpg' problem

## 0.1.0 support video

support video in android.
and will change api from ImageXXXX to AssetXXXX

## 0.0.3 fix bug

update for the issue #1 (NPE when request other permission on android)

## 0.0.2 update readme

## 0.0.1

first version

api for photo
