import 'package:photo_manager/photo_manager.dart';

void main(List<String> args) {
  final filter = AdvancedCustomFilter().addWhereCondition(
    WhereConditionGroup()
        .andGroup(
          WhereConditionGroup()
              .andText('width > 1000')
              .andText('height > 1000'),
        )
        .orGroup(
          WhereConditionGroup().andText('width < 500').andText('height < 500'),
        ),
  );

  PhotoManager.getAssetPathList(filterOption: filter).then((value) {
    print(value);
  });
}
