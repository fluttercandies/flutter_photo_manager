// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.
import 'package:flutter/foundation.dart';

import '../internal/constants.dart';
import '../internal/enums.dart';

/// The dimensions of the thumbnail data for an [AssetEntity].
@immutable
class ThumbnailSize {
  /// Creates a new [ThumbnailSize] object with the given width and height.
  const ThumbnailSize(this.width, this.height);

  /// Creates a square [ThumbnailSize] with the given dimension.
  const ThumbnailSize.square(int dimension)
      : width = dimension,
        height = dimension;

  /// The width in pixels.
  final int width;

  /// The height in pixels.
  final int height;

  /// Whether this size encloses a non-zero area.
  ///
  /// Negative areas are considered empty.
  bool get isEmpty => width <= 0 || height <= 0;

  /// A [ThumbnailSize] with the [width] and [height] swapped.
  ThumbnailSize get flipped => ThumbnailSize(height, width);

  @override
  bool operator ==(Object other) {
    if (other is! ThumbnailSize) {
      return false;
    }
    return other.width == width && other.height == height;
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode;

  @override
  String toString() => 'ThumbnailSize($width, $height)';
}

/// The options used when requesting thumbnails.
@immutable
class ThumbnailOption {
  /// Creates a new [ThumbnailOption] object with the given parameters.
  const ThumbnailOption({
    required this.size,
    this.format = ThumbnailFormat.jpeg,
    this.quality = PMConstants.vDefaultThumbnailQuality,
    this.frame = 0,
  });

  /// Constructs thumbnail options for iOS/macOS only.
  factory ThumbnailOption.ios({
    required ThumbnailSize size,
    ThumbnailFormat format = ThumbnailFormat.jpeg,
    int quality = PMConstants.vDefaultThumbnailQuality,
    DeliveryMode deliveryMode = DeliveryMode.opportunistic,
    ResizeMode resizeMode = ResizeMode.fast,
    ResizeContentMode resizeContentMode = ResizeContentMode.fit,
  }) {
    return _IOSThumbnailOption(
      size: size,
      format: format,
      quality: quality,
      deliveryMode: deliveryMode,
      resizeMode: resizeMode,
      resizeContentMode: resizeContentMode,
    );
  }

  /// The size of the thumbnail.
  final ThumbnailSize size;

  /// The format of the thumbnail.
  ///
  /// See [ThumbnailFormat] for available formats.
  final ThumbnailFormat format;

  /// The quality value for the thumbnail.
  ///
  /// Must be a value between 1 and 100 (inclusive).
  ///
  /// Defaults to [PMConstants.vDefaultThumbnailQuality].
  final int quality;

  /// {@template photo_manager.ThumbnailOption.frame}
  /// The frame number when loading a thumbnail for videos.
  ///
  /// This field is only used on Android, since Glide accepts the `frame`
  /// option in request options.
  ///
  /// Defaults to 0.
  /// {@endtemplate}
  final int frame;

  /// Converts this object to a map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': size.width,
      'height': size.height,
      'format': format.index,
      'quality': quality,
      'frame': frame,
    };
  }

  /// Checks that the assertions for this object are valid.
  void checkAssertions() {
    assert(!size.isEmpty, 'The size must not be empty.');
    assert(
      quality > 0 && quality <= 100,
      'The quality must be between 1 and 100',
    );
  }

  @override
  int get hashCode =>
      size.hashCode ^ format.hashCode ^ quality.hashCode ^ frame.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! ThumbnailOption) {
      return false;
    }
    return size == other.size &&
        format == other.format &&
        quality == other.quality &&
        frame == other.frame;
  }
}

/// A version of [ThumbnailOption] that is used on iOS/macOS only.
@immutable
class _IOSThumbnailOption extends ThumbnailOption {
  /// Creates a new [_IOSThumbnailOption] object with the given parameters.
  const _IOSThumbnailOption({
    required ThumbnailSize size,
    ThumbnailFormat format = ThumbnailFormat.jpeg,
    int quality = PMConstants.vDefaultThumbnailQuality,
    required this.deliveryMode,
    required this.resizeMode,
    required this.resizeContentMode,
  }) : super(size: size, format: format, quality: quality);

  /// The delivery mode for the thumbnail.
  final DeliveryMode deliveryMode;

  /// The resize mode for the thumbnail.
  final ResizeMode resizeMode;

  /// The resize content mode for the thumbnail.
  final ResizeContentMode resizeContentMode;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      ...super.toMap(),
      'deliveryMode': deliveryMode.index,
      'resizeMode': resizeMode.index,
      'resizeContentMode': resizeContentMode.index,
    };
  }

  @override
  int get hashCode =>
      super.hashCode ^
      deliveryMode.hashCode ^
      resizeMode.hashCode ^
      resizeContentMode.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! _IOSThumbnailOption) {
      return false;
    }
    return size == other.size &&
        format == other.format &&
        quality == other.quality &&
        frame == other.frame &&
        deliveryMode == other.deliveryMode &&
        resizeMode == other.resizeMode &&
        resizeContentMode == other.resizeContentMode;
  }
}
