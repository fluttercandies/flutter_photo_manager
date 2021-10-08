/// asset type
///
/// 用于资源类型属性
enum AssetType {
  /// not image or video
  ///
  /// 不是图片 也不是视频
  other,

  /// image
  image,

  /// video
  video,

  /// audio
  audio,
}

/// For generality, only support jpg and png.
enum ThumbFormat { jpeg, png }

enum DeliveryMode { opportunistic, highQualityFormat, fastFormat }

/// Resize strategy, useful when need exact image size. It's must be used only for iOS
/// [Apple resize mode documentation](https://developer.apple.com/documentation/photokit/phimagerequestoptions/1616988-resizemode?language=swift)
enum ResizeMode { none, fast, exact }

/// Resize content mode
enum ResizeContentMode { fit, fill, def }

enum OrderOptionType { createDate, updateDate }

/// Current asset loading status
enum PMRequestState { prepare, loading, success, failed }

/// Android: The effective values are [authorized] or [denied].
///
/// iOS/macOS: All values are valid.
///
/// See [document of Apple](https://developer.apple.com/documentation/photokit/phauthorizationstatus?language=objc)
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
  /// The state is only support iOS 14 or higher.
  limited,
}

enum IosAccessLevel { addOnly, readWrite }
