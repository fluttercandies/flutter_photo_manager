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

class RequestType {
  final int value;

  int get index => value;

  static const _imageValue = 1;
  static const _videoValue = 1 << 1;
  static const _audioValue = 1 << 2;

  static const image = RequestType(_imageValue);
  static const video = RequestType(_videoValue);
  static const audio = RequestType(_audioValue);
  static const all = RequestType(_imageValue | _videoValue | _audioValue);
  static const common = RequestType(_imageValue | _videoValue);

  const RequestType(this.value);

  bool containsImage() {
    return value & _imageValue == _imageValue;
  }

  bool containsVideo() {
    return value & _videoValue == _videoValue;
  }

  bool containsAudio() {
    return value & _audioValue == _audioValue;
  }

  bool containsType(RequestType type) {
    return this.value & type.value == type.value;
  }

  RequestType operator +(RequestType type) {
    return this | type;
  }

  RequestType operator -(RequestType type) {
    return this ^ type;
  }

  RequestType operator |(RequestType type) {
    return RequestType(this.value | type.value);
  }

  RequestType operator ^(RequestType type) {
    return RequestType(this.value ^ type.value);
  }

  RequestType operator >>(int bit) {
    return RequestType(this.value >> bit);
  }

  RequestType operator <<(int bit) {
    return RequestType(this.value << bit);
  }

  @override
  String toString() {
    return "Request type = $value";
  }
}

/// For generality, only support jpg and png.
enum ThumbFormat { jpeg, png }
