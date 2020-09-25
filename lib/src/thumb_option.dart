import 'package:flutter/material.dart';

import 'type.dart';

class ThumbOption {
  final int width;
  final int height;
  final ThumbFormat format;
  final int quality;

  ThumbOption({
    @required this.width,
    @required this.height,
    this.format = ThumbFormat.jpeg,
    this.quality = 95,
  });

  Map<String, dynamic> toMap() {
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
    assert(format != null, "The format must not be null.");
    assert(quality > 0 && quality <= 100, "The quality must between 0 and 100");
  }
}
