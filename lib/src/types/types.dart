import '../internal/enums.dart';

/// The request type when requesting paths.
///
///  * [all] - Request paths that return all kind of assets.
///  * [common] - Request paths that return images and videos.
///  * [image] - Request paths that only return images.
///  * [video] - Request paths that only return videos.
///  * [audio] - Request paths that only return audios.
class RequestType {
  const RequestType(this.value);

  final int value;

  static const _imageValue = 1;
  static const _videoValue = 1 << 1;
  static const _audioValue = 1 << 2;

  static const all = RequestType(_imageValue | _videoValue | _audioValue);
  static const common = RequestType(_imageValue | _videoValue);
  static const image = RequestType(_imageValue);
  static const video = RequestType(_videoValue);
  static const audio = RequestType(_audioValue);

  bool containsImage() => value & _imageValue == _imageValue;

  bool containsVideo() => value & _videoValue == _videoValue;

  bool containsAudio() => value & _audioValue == _audioValue;

  bool containsType(RequestType type) => value & type.value == type.value;

  RequestType operator +(RequestType type) => this | type;

  RequestType operator -(RequestType type) => this ^ type;

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
  bool operator ==(Object other) =>
      other is RequestType && value == other.value;

  @override
  int get hashCode => value;

  @override
  String toString() => '$runtimeType($value)';
}

/// See [PermissionState].
class PermisstionRequestOption {
  const PermisstionRequestOption({
    this.iosAccessLevel = IosAccessLevel.readWrite,
  });

  final IosAccessLevel iosAccessLevel;

  Map<String, dynamic> toMap() => {'iosAccessLevel': iosAccessLevel.index + 1};
}
