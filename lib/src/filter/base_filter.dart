enum BaseFilterType {
  classical,
  custom,
}

extension BaseFilterTypeExtension on BaseFilterType {
  int get value {
    switch (this) {
      case BaseFilterType.classical:
        return 0;
      case BaseFilterType.custom:
        return 1;
    }
  }
}

abstract class BaseFilter {
  BaseFilter();

  /// Whether the [AssetPathEntity]s will return with modified time.
  ///
  /// This option is performance-consuming. Use with cautious.
  ///
  /// See also:
  ///  * [AssetPathEntity.lastModified].
  bool containsPathModified = false;

  /// Whether to obtain live photos.
  ///
  /// This option only takes effects on iOS.
  bool containsLivePhotos = true;

  /// Whether to obtain only live photos.
  ///
  /// This option only takes effects on iOS and when the request type is image.
  bool onlyLivePhotos = false;

  BaseFilterType get type;

  Map<String, dynamic> childMap();

  BaseFilter updateDateToNow();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.value,
      'child': childMap(),
      ..._paramMap(),
    };
  }

  Map<String, dynamic> _paramMap() {
    return <String, dynamic>{
      'containsPathModified': containsPathModified,
      'containsLivePhotos': containsLivePhotos,
      'onlyLivePhotos': onlyLivePhotos,
    };
  }
}
