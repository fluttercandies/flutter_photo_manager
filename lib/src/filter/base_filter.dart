import 'package:photo_manager/photo_manager.dart';

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

  factory BaseFilter.defaultValue({
    bool containsPathModified = false,
  }) {
    return CustomFilter.sql(
      where: '',
      orderBy: [
        OrderByItem.named(
          column: CustomColumns.base.createDate,
          isAsc: false,
        ),
      ],
    );
  }

  /// Whether the [AssetPathEntity]s will return with modified time.
  ///
  /// This option is performance-consuming. Use with cautious.
  ///
  /// See also:
  ///  * [AssetPathEntity.lastModified].
  bool containsPathModified = false;

  BaseFilterType get type;

  Map<String, dynamic> childMap();

  BaseFilter updateDateToNow();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.value,
      'child': {
        ...childMap(),
        ..._paramMap(),
      },
    };
  }

  Map<String, dynamic> _paramMap() {
    return <String, dynamic>{
      'containsPathModified': containsPathModified,
    };
  }
}
