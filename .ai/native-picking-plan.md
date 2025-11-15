# Plan for Integrating Native Pickers into flutter_photo_manager

This document outlines the plan to integrate native photo pickers on Android and iOS into the `flutter_photo_manager` plugin. The goal is to allow users to pick media without requiring broad storage permissions, and then convert the selected media into `AssetEntity` objects.

## 1. Dart API Changes

- **Modify `PhotoManager`:**
  - Add a new static method to the `PhotoManager` class:
    ```dart
    static Future<List<AssetEntity>> pickAssets(
      BuildContext context, {
      int maxCount = 9,
      RequestType requestType = RequestType.common,
    });
    ```
  - This method will invoke a new method on the method channel, e.g., `picker.pickAssets`.

- **Update `AssetEntity`:**
  - The existing `AssetEntity` should be usable as is. The native side will be responsible for fetching all the required properties to construct a valid `AssetEntity` on the Dart side. We will try to avoid adding platform-specific fields to `AssetEntity` to keep the model consistent.

## 2. Android Implementation

- **Use the Photo Picker:**
  - The native Android implementation will use the `PickVisualMedia` Activity Result contract, which is the recommended way to use the photo picker on modern Android versions.
  - A new method will be added to the `PhotoManagerPlugin` to handle the `picker.pickAssets` method channel call.
  - The implementation will launch the photo picker.
  - After the user selects media, the plugin will receive a list of URIs.
  - For each URI, the plugin will use a `ContentResolver` to query the `MediaStore` and retrieve the necessary information (ID, display name, size, duration, etc.) to construct a map that can be sent back to the Dart side to create `AssetEntity` objects.
  - This approach avoids the need for `READ_MEDIA_IMAGES` or `READ_MEDIA_VIDEOS` permissions when only using the picker.

## 3. iOS/macOS Implementation

- **Use `PHPickerViewController`:**
  - The native iOS/macOS implementation will use `PHPickerViewController`, which is Apple's recommended way to let users pick media without granting full photo library access.
  - A new method will be added to the `PhotoManagerPlugin.m` file to handle the `picker.pickAssets` method channel call.
  - The implementation will present the `PHPickerViewController`.
  - After the user selects media, the delegate method will receive `PHPickerResult` objects.
  - For each `PHPickerResult`, we will get the `assetIdentifier`. This identifier can be used to fetch the corresponding `PHAsset`.
  - By fetching the `PHAsset`, we can reuse the existing logic that converts a `PHAsset` into a dictionary to be sent to the Dart side for creating an `AssetEntity`. This avoids duplicating logic and ensures consistency.

## 4. Example App

- **Add a new UI for testing:**
  - The example app will be updated with a new button or page to test the native picker functionality.
  - This will allow for easy verification of the feature on both Android and iOS.

## 5. Documentation

- **Update `README.md`:**
  - The main `README.md` file will be updated to document the new `PhotoManager.pickAssets` method.
  - The documentation will explain how to use the method and highlight the benefit of not needing broad storage permissions.
- **Update `CHANGELOG.md`:**
  - A new entry will be added to the `CHANGELOG.md` to describe the new feature.

## 6. Handling `NSItemProvider` for Picked Assets

To support cases where a `PHAsset` is not available (e.g., when picking from iCloud without local download), we need a mechanism to handle assets backed by `NSItemProvider`.

- **Create a new `PMAsset` class for local assets:**
  - This class will hold asset details obtained from `NSItemProvider`.
  - It will have a unique identifier to distinguish it from `PHAsset`-backed entities. A good unique ID could be the current timestamp combined with a random number.

- **Caching Mechanism:**
  - A cache will be implemented on the native side to store these `PMAsset` objects.
  - When `PhotoManager.pickAssets` is called with `useItemProvider: true`, the native side will not fetch `PHAsset`s. Instead, it will create and cache `PMAsset` objects.

- **Flutter to Native Communication:**
  - The `useItemProvider` flag will be passed from the Dart `pickAssets` method to the native iOS/macOS implementation.

- **Native to Flutter Communication:**
  - When an asset is backed by `NSItemProvider`, a special property (e.g., `isLocal: true` or `source: 'itemProvider'`) will be added to the map sent back to Dart.
  - The `AssetEntity` constructor on the Dart side will use this property to identify such assets.

- **AssetEntity updates:**
  - A new property, such as `isLocal`, will be added to `AssetEntity` to flag that it's not a standard `PHAsset`.
  - Methods like `thumbnailData` on `AssetEntity` will need to be updated. If `isLocal` is true, it will need to request the thumbnail data from the native side, which will in turn load it from the `NSItemProvider`.

## 7. Enrich `AssetEntity` from `NSItemProvider`

1.  **Enhance `AssetEntity` for cached assets**: For assets that are backed by `NSItemProvider` and must use local caches, ensure that as many `AssetEntity` APIs as possible are functional. This includes methods like `thumbnailData`, `getMediaUrl`, etc.
2.  **Extract more metadata**: Convert as much metadata as possible from the `NSItemProvider` to the `AssetEntity`. This includes:
    *   Title
    *   Favorite status
    *   Media subtypes
    *   Latitude and longitude

## 8. Persistence and Refactoring

1.  **Persist `itemProviderAssetCache`**: The `itemProviderAssetCache` is now persisted to a file in the app's documents directory. This ensures that the cache is not lost when the app is terminated.
2.  **Refactor `NSItemProvider`-related code**: The `NSItemProvider`-related code has been abstracted into a separate helper class, `PMItemProviderHelper`, to improve the project structure.

## 9. Notification Handling Refactoring

1.  **Delegate Notification Handling to `PMManager`**: The `PMManager` now conforms to the `PHPhotoLibraryChangeObserver` protocol and is responsible for handling `PHPhotoLibrary` change notifications.
2.  **Pass `PMNotificationManager` to `PMManager`**: The `PMNotificationManager` is now passed to the `PMManager` so that the `PMManager` can delegate the notification handling to it. This improves the separation of concerns and makes the code more modular.

## 10. Live Photo Handling

- **Handle Live Photo `.pvt` directories**: The `handleLivePhoto` method in `PMItemProviderHelper.m` now correctly handles live photos that are represented as a directory (`.pvt`). It inspects the directory, finds the image and video components, and extracts the necessary information from both to create a complete `AssetEntity`.
