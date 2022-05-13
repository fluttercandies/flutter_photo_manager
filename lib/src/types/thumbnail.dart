// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../internal/constants.dart';
import '../internal/enums.dart';

@immutable
class ThumbnailSize {
  const ThumbnailSize(this.width, this.height);

  /// Creates a square [ThumbnailSize] whose [width] and [height]
  /// are the given dimension.
  const ThumbnailSize.square(int dimension)
      : width = dimension,
        height = dimension;

  /// The width pixels.
  final int width;

  /// The height pixels.
  final int height;

  /// Whether this size encloses a non-zero area.
  ///
  /// Negative areas are considered empty.
  bool get isEmpty => width <= 0 || height <= 0;

  /// A [ThumbnailSize] with the [width] and [height] swapped.
  ThumbnailSize get flipped => ThumbnailSize(height, width);

  /// Compares two Sizes for equality.
  // We don't compare the runtimeType because of _DebugSize in the framework.
  @override
  bool operator ==(Object other) {
    return other is ThumbnailSize &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => hashValues(width, height);

  @override
  String toString() => 'ThumbnailSize($width, $height)';
}

/// The thumbnail option when requesting assets.
@immutable
class ThumbnailOption {
  const ThumbnailOption({
    required this.size,
    this.format = ThumbnailFormat.jpeg,
    this.quality = PMConstants.vDefaultThumbnailQuality,
    this.frame = 0,
  });

  /// Construct thumbnail options only for iOS/macOS.
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

  /// The thumbnail size.
  final ThumbnailSize size;

  /// {@macro photo_manager.ThumbnailFormat}
  final ThumbnailFormat format;

  /// The quality value for the thumbnail.
  ///
  /// Valid from 1 to 100.
  /// Defaults to [PMConstants.vDefaultThumbnailQuality].
  final int quality;

  /// The frame when loading thumbnail for videos.
  ///
  /// This field only works for Android, since Glide accept the frame option
  /// in request options.
  ///
  /// Defaults to 0.
  final int frame;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': size.width,
      'height': size.height,
      'format': format.index,
      'quality': quality,
      'frame': frame,
    };
  }

  void checkAssertions() {
    assert(!size.isEmpty, 'The size must not be empty.');
    assert(
      quality > 0 && quality <= 100,
      'The quality must between 1 and 100',
    );
  }

  @override
  int get hashCode => hashValues(size, format, quality, frame);

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

@immutable
class _IOSThumbnailOption extends ThumbnailOption {
  const _IOSThumbnailOption({
    required ThumbnailSize size,
    ThumbnailFormat format = ThumbnailFormat.jpeg,
    int quality = PMConstants.vDefaultThumbnailQuality,
    required this.deliveryMode,
    required this.resizeMode,
    required this.resizeContentMode,
  }) : super(size: size, format: format, quality: quality);

  final DeliveryMode deliveryMode;
  final ResizeMode resizeMode;
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
      hashValues(super.hashCode, deliveryMode, resizeMode, resizeContentMode);

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
