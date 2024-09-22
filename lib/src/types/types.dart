// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../filter/path_filter.dart';
import '../internal/constants.dart';
import '../internal/enums.dart';
import '../internal/map_interface.dart';

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

  /// The values of [RequestType].
  static const values = <RequestType>[image, video, audio];

  /// Computes the request type from given types.
  static RequestType fromTypes(List<RequestType> types) {
    RequestType result = const RequestType(0);
    for (final type in types) {
      result += type;
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is RequestType && value == other.value;

  @override
  int get hashCode => value;

  @override
  String toString() {
    final values = <String>[];
    if (containsImage()) {
      values.add('image');
    }
    if (containsVideo()) {
      values.add('video');
    }
    if (containsAudio()) {
      values.add('audio');
    }
    return 'RequestType(${values.join(', ')})';
  }
}

/// See [PermissionState].
@immutable
class PermissionRequestOption with IMapMixin {
  const PermissionRequestOption({
    this.iosAccessLevel = IosAccessLevel.readWrite,
    this.androidPermission = const AndroidPermission(
      type: RequestType.common,
      mediaLocation: false,
    ),
    this.ohosPermissions = PMConstants.vDefaultOhosPermissions,
  });

  /// See [IosAccessLevel].
  final IosAccessLevel iosAccessLevel;

  /// See [AndroidPermission].
  final AndroidPermission androidPermission;

  /// The requesting permission list for the OHOS.
  final List<String> ohosPermissions;

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'iosAccessLevel': iosAccessLevel.index + 1,
        'androidPermission': androidPermission.toMap(),
        'ohosPermissions': ohosPermissions,
      };

  @override
  bool operator ==(Object other) =>
      other is PermissionRequestOption &&
      iosAccessLevel == other.iosAccessLevel &&
      androidPermission == other.androidPermission &&
      ohosPermissions.every((p) => other.ohosPermissions.contains(p)) &&
      other.ohosPermissions.every((n) => ohosPermissions.contains(n));

  @override
  int get hashCode => iosAccessLevel.hashCode;
}

/// The permission for android.
class AndroidPermission with IMapMixin {
  const AndroidPermission({
    required this.type,
    required this.mediaLocation,
  });

  /// The type of your need.
  ///
  /// See [RequestType].
  final RequestType type;

  /// Whether you need to access the media location.
  /// You must define `<uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION" />` in your AndroidManifest.xml.
  ///
  /// If you do not define in AndroidManifest, or [mediaLocation] is false, this permission will not be applied for.
  ///
  /// See it in [android](https://developer.android.com/reference/android/Manifest.permission#ACCESS_MEDIA_LOCATION).
  final bool mediaLocation;

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type.value,
        'mediaLocation': mediaLocation,
      };
}

/// The extra information of the album type.
class AlbumType {
  const AlbumType({this.darwin, this.ohos});

  /// The extra information of the album type on macOS and iOS.
  final DarwinAlbumType? darwin;

  /// The extra information of the album type on OpenHarmony.
  final OhosAlbumType? ohos;

  @override
  bool operator ==(Object other) {
    if (other is! AlbumType) {
      return false;
    }
    return darwin == other.darwin && ohos == other.ohos;
  }

  @override
  int get hashCode => darwin.hashCode ^ ohos.hashCode;
}

/// The extra information of the album type on macOS and iOS.
class DarwinAlbumType {
  const DarwinAlbumType({this.subtype, this.type});

  /// The darwin collection type, in android, the value is always null.
  ///
  /// If the [type] is 2, the value will be null.
  ///
  ///
  final PMDarwinAssetCollectionType? type;

  /// The darwin collection subtype, in android, the value is always null.
  ///
  /// If the [type] is 2, the value will be null.
  ///
  final PMDarwinAssetCollectionSubtype? subtype;

  @override
  bool operator ==(Object other) {
    if (other is! DarwinAlbumType) {
      return false;
    }
    return type == other.type && subtype == other.subtype;
  }

  @override
  int get hashCode => type.hashCode ^ subtype.hashCode;
}

/// The extra information of the album type on OpenHarmony.
class OhosAlbumType {
  const OhosAlbumType({this.subtype, this.type});

  /// The type of the album on ohos.
  final PMOhosAlbumType? type;

  /// The subtype of the album on ohos.
  final PMOhosAlbumSubtype? subtype;

  @override
  bool operator ==(Object other) {
    if (other is! OhosAlbumType) {
      return false;
    }
    return type == other.type && subtype == other.subtype;
  }

  @override
  int get hashCode => type.hashCode ^ subtype.hashCode;
}
