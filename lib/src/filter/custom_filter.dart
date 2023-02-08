import 'package:photo_manager/src/filter/base_filter.dart';

class CustomFilter extends BaseFilter {
  @override
  BaseFilterType get type => BaseFilterType.custom;

  @override
  Map<String, dynamic> childMap() {
    return <String, dynamic>{
      'where': makeWhere(),
      'orderBy': makeOrderBy(),
    };
  }

  @override
  BaseFilter updateDateToNow() {
    throw UnimplementedError();
  }

  String makeWhere() {
    return '';
  }

  String makeOrderBy() {
    return '';
  }
}
