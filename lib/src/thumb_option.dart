import 'package:flutter/material.dart';

import 'type.dart';

class ThumbOption {
  final int width;
  final int height;
  final ThumbFormat format;
  final int quality;

  const ThumbOption({
    @required this.width,
    @required this.height,
    this.format = ThumbFormat.jpeg,
    this.quality = 95,
  });

  factory ThumbOption.ios({
    @required int width,
    @required int height,
    ThumbFormat format = ThumbFormat.jpeg,
    int quality = 95,
    DeliveryMode deliveryMode = DeliveryMode.opportunistic,
    ResizeMode resizeMode = ResizeMode.none,
    ResizeContentMode resizeContentMode = ResizeContentMode.fit,
  }) {
    return _IosThumbOption(
      width: width,
      height: height,
      format: format,
      quality: quality,
      deliveryMode: deliveryMode,
      resizeMode: resizeMode,
      resizeContentMode: resizeContentMode,
    );
  }

  Map<String, Object> toMap() {
    return {
      'width': width,
      'height': height,
      'format': format.index,
      'quality': quality,
    };
  }

  void checkAssert() {
    assert(width != null && height != null,
        "The width and height must not be null.");
    assert(width > 0 && height > 0, "The width and height must better 0.");
    assert(quality > 0 && quality <= 100, "The quality must between 0 and 100");
    _checkNotNull('format', format);
  }

  void _checkNotNull(String key, value) {
    assert(value != null, 'The $key must not be null.');
  }
}

class _IosThumbOption extends ThumbOption {
  final DeliveryMode deliveryMode;
  final ResizeMode resizeMode;
  final ResizeContentMode resizeContentMode;

  _IosThumbOption({
    @required int width,
    @required int height,
    ThumbFormat format = ThumbFormat.jpeg,
    int quality = 95,
    this.deliveryMode,
    this.resizeMode,
    this.resizeContentMode,
  }) : super(
          width: width,
          height: height,
          format: format,
          quality: quality,
        );

  @override
  void checkAssert() {
    super.checkAssert();
    _checkNotNull('deliveryMode', deliveryMode);
    _checkNotNull('resizeMode', resizeMode);
    _checkNotNull('resizeContentMode', resizeContentMode);
  }

  @override
  Map<String, Object> toMap() {
    return <String, Object>{
      'deliveryMode': deliveryMode.index,
      'resizeMode': resizeMode.index,
      'resizeContentMode': resizeContentMode.index,
    }..addAll(super.toMap());
  }
}
