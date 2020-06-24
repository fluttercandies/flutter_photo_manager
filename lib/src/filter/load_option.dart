import '../type.dart';

abstract class LoadOption {
  final int width;
  final int height;

  /// Image format, jpeg, png
  final ThumbFormat format;
  final int quality;

  const LoadOption(this.width, this.height,
      {this.format = ThumbFormat.jpeg, this.quality = 100});

  Map<String, dynamic> toMap() {
    return {
      "width": width,
      "height": height,
      "format": format.index,
      "quality": quality,
    };
  }
}

class DefaultLoadOption extends LoadOption {
  const DefaultLoadOption(int width, int height,
      {ThumbFormat format = ThumbFormat.jpeg, int quality = 100})
      : super(width, height, format: format, quality: quality);
}

/// Must be used for set iOS specific parameters
class IosLoadOption extends LoadOption {
  /// Load image strategy, by default `opportunistic`
  final DeliveryMode deliveryMode;

  /// Can be used for get cropped image, by default `fast`
  final ResizeMode resizeMode;

  /// Resize content mode, by default `fill`
  final ResizeContentMode contentMode;

  const IosLoadOption(int width, int height,
      {ThumbFormat format = ThumbFormat.jpeg,
      int quality = 100,
      this.deliveryMode = DeliveryMode.opportunistic,
      this.resizeMode = ResizeMode.fast,
      this.contentMode = ResizeContentMode.fill})
      : super(width, height, format: format, quality: quality);

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    map["deliveryMode"] = deliveryMode.index;
    map["resizeMode"] = resizeMode.index;
    map["contentMode"] = contentMode.index;

    return map;
  }
}
