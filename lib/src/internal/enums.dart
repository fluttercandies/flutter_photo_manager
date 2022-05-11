// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

/// {@template photo_manager.AssetType}
/// The type of the asset.
///
/// Most of assets are [AssetType.image] and [AssetType.video],
/// some assets might be [AssetType.audio] on Android.
/// The [AssetType.other] type won't show in general.
/// {@endtemplate}
///
/// **IMPORTANT FOR MAINTAINERS:** **DO NOT** change orders of values.
enum AssetType {
  other,
  image,
  video,
  audio,
}

/// {@template photo_manager.ThumbnailFormat}
/// Which format the thumbnail should be, generally support JPG and PNG.
/// {@endtemplate}
enum ThumbnailFormat { jpeg, png }

/// Enumeration for `PHImageRequestOptionsDeliveryMode` on iOS/macOS.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phimagerequestoptionsdeliverymode)
enum DeliveryMode { opportunistic, highQualityFormat, fastFormat }

/// Specifies how to resize the requested image on iOS/macOS.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phimagerequestoptions/1616988-resizemode)
enum ResizeMode { none, fast, exact }

/// Fitting an image’s aspect ratio to a requested size on iOS/macOS.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phimagecontentmode)
enum ResizeContentMode { fit, fill, def }

enum OrderOptionType { createDate, updateDate }

/// {@template photo_manager.PMRequestState}
/// Indicate the current state when an asset is loading with [PMProgressHandler].
/// {@endtemplate}
enum PMRequestState { prepare, loading, success, failed }

/// Information about app’s authorization to access the user’s photo library.
///  * Android: Only [authorized] and [denied] are valid.
///  * iOS/macOS: All valid.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phauthorizationstatus)
enum PermissionState {
  /// The user hasn’t set the app’s authorization status.
  notDetermined,

  /// The app isn’t authorized to access the photo library, and the user can’t grant such permission.
  restricted,

  /// The user explicitly denied this app access to the photo library.
  denied,

  /// The user explicitly granted this app access to the photo library.
  authorized,

  /// The user authorized this app for limited photo library access.
  ///
  /// This state only supports iOS 14 and above.
  limited,
}

/// The app’s level of access to the user’s photo library.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phaccesslevel)
enum IosAccessLevel { addOnly, readWrite }

/// Common file types for images.
enum ImageFileType { jpg, png, gif, tiff, heic, other }

/// Some special image types.
enum SpecialImageType { gif, heic }
