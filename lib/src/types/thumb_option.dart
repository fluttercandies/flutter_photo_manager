import '../internal/enums.dart';

/// The thumbnail option when requesting assets.
class ThumbOption {
  const ThumbOption({
    required this.width,
    required this.height,
    this.format = ThumbFormat.jpeg,
    this.quality = 95,
  });

  /// Construct thumbnail options only for iOS/macOS.
  factory ThumbOption.ios({
    required int width,
    required int height,
    ThumbFormat format = ThumbFormat.jpeg,
    int quality = 95,
    DeliveryMode deliveryMode = DeliveryMode.opportunistic,
    ResizeMode resizeMode = ResizeMode.fast,
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

  /// The width pixels.
  final int width;

  /// The height pixels.
  final int height;

  /// {@macro photo_manager.ThumbnailFormat}
  final ThumbFormat format;

  /// The quality value for the thumbnail.
  ///
  /// Valid from 1 to 100. Defaults to 95.
  final int quality;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
      'format': format.index,
      'quality': quality,
    };
  }

  void checkAssertions() {
    assert(
      width > 0 && height > 0,
      "The width and height must be greater than 0.",
    );
    assert(
      quality > 0 && quality <= 100,
      "The quality must between 1 and 100",
    );
  }
}

class _IosThumbOption extends ThumbOption {
  const _IosThumbOption({
    required int width,
    required int height,
    ThumbFormat format = ThumbFormat.jpeg,
    int quality = 95,
    required this.deliveryMode,
    required this.resizeMode,
    required this.resizeContentMode,
  }) : super(
          width: width,
          height: height,
          format: format,
          quality: quality,
        );

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
}
