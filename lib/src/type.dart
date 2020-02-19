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
}

enum RequestType {
  all,
  image,
  video,
}

/// For generality, only support jpg and png.
enum ThumbFormat { jpeg, png }
