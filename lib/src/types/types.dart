// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../internal/enums.dart';

/// The request type when requesting paths.
///
///  * [all] - Request paths that return all kind of assets.
///  * [common] - Request paths that return images and videos.
///  * [image] - Request paths that only return images.
///  * [video] - Request paths that only return videos.
///  * [audio] - Request paths that only return audios.
@immutable
class RequestType {
  const RequestType(this.value);

  final int value;

  static const int _imageValue = 1;
  static const int _videoValue = 1 << 1;
  static const int _audioValue = 1 << 2;

  static const RequestType all = RequestType(
    _imageValue | _videoValue | _audioValue,
  );
  static const RequestType common = RequestType(_imageValue | _videoValue);
  static const RequestType image = RequestType(_imageValue);
  static const RequestType video = RequestType(_videoValue);
  static const RequestType audio = RequestType(_audioValue);

  bool containsImage() => value & _imageValue == _imageValue;

  bool containsVideo() => value & _videoValue == _videoValue;

  bool containsAudio() => value & _audioValue == _audioValue;

  bool containsType(RequestType type) => value & type.value == type.value;

  RequestType operator +(RequestType type) => this | type;

  RequestType operator -(RequestType type) => this ^ type;

  RequestType operator |(RequestType type) {
    return RequestType(value | type.value);
  }

  RequestType operator ^(RequestType type) {
    return RequestType(value ^ type.value);
  }

  RequestType operator >>(int bit) {
    return RequestType(value >> bit);
  }

  RequestType operator <<(int bit) {
    return RequestType(value << bit);
  }

  @override
  bool operator ==(Object other) =>
      other is RequestType && value == other.value;

  @override
  int get hashCode => value;

  @override
  String toString() => '$runtimeType($value)';
}

@Deprecated(
  'Use PermissionRequestOption instead. This will be removed in 3.0.0',
)
typedef PermisstionRequestOption = PermissionRequestOption;

/// See [PermissionState].
@immutable
class PermissionRequestOption {
  const PermissionRequestOption({
    this.iosAccessLevel = IosAccessLevel.readWrite,
  });

  final IosAccessLevel iosAccessLevel;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'iosAccessLevel': iosAccessLevel.index + 1,
      };

  @override
  bool operator ==(Object other) =>
      other is PermissionRequestOption &&
      iosAccessLevel == other.iosAccessLevel;

  @override
  int get hashCode => iosAccessLevel.hashCode;
}
