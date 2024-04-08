import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

class CustomFilterPage extends StatefulWidget {
  const CustomFilterPage({super.key});

  @override
  State<CustomFilterPage> createState() => _CustomFilterPageState();
}

class _CustomFilterPageState extends State<CustomFilterPage> {
  static const columns = CustomColumns.base;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevCustomFilterPage'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text(
              'Click button to show filter log in console',
              textAlign: TextAlign.center,
            ),
            ...[
              filterButton(_sqlFilter),
              filterButton(_widthFilter),
              filterButton(_advancedFilter),
            ].map(
              (e) => Container(
                // alignment: Alignment.center,
                width: double.infinity,
                margin: const EdgeInsets.all(8.0),
                child: e,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filterButton(ValueGetter<CustomFilter> filterBuilder) {
    final filter = filterBuilder();
    return ListTile(
      title: Text('Filter: ${filter.makeWhere()}'),
      subtitle: Text('Order by: ${filter.makeOrderBy()}'),
      onTap: () async {
        final where = filter.makeWhere();
        final orderBy = filter.makeOrderBy();

        print('where: $where');
        print('orderBy: $orderBy');

        final permissionResult = await PhotoManager.requestPermissionExtend();
        if (!permissionResult.hasAccess) {
          showToast('No permission to access photo');
          return;
        }

        const type = RequestType.all;

        final assetCount = await PhotoManager.getAssetCount(
          type: type,
          filterOption: filter,
        );

        print('The asset count is $assetCount');

        final assetList = await PhotoManager.getAssetListPaged(
          page: 0,
          pageCount: 20,
          filterOption: filter,
          type: type,
        );

        for (final asset in assetList) {
          final info = StringBuffer();
          info.writeln('id: ${asset.id}');
          info.writeln('  type: ${asset.type}');
          info.writeln('  width: ${asset.width}');
          info.writeln('  height: ${asset.height}');
          info.writeln('  duration: ${asset.duration}');
          info.writeln('  size: ${asset.size}');
          info.writeln('  createDt: ${asset.createDateTime}');
          info.writeln('  modifiedDt: ${asset.modifiedDateTime}');
          info.writeln('  latitude: ${asset.latitude}');
          info.writeln('  longitude: ${asset.longitude}');
          info.writeln('  orientation: ${asset.orientation}');
          info.writeln('  isFavorite: ${asset.isFavorite}');

          info.writeln();

          print(info);
        }
      },
    );
  }

  CustomFilter _sqlFilter() {
    return CustomFilter.sql(
      where: '',
      orderBy: [
        OrderByItem.desc(CustomColumns.base.width),
      ],
    );
  }

  CustomFilter _widthFilter() {
    return CustomFilter.sql(
      where: '${columns.width} >= 1000',
      orderBy: [
        OrderByItem.desc(CustomColumns.base.width),
      ],
    );
  }

  CustomFilter _advancedFilter() {
    final subGroup1 = WhereConditionGroup()
        .and(
          ColumnWhereCondition(
            column: columns.height,
            operator: '<',
            value: '100',
          ),
        )
        .or(
          ColumnWhereCondition(
            column: columns.height,
            operator: '>',
            value: '1000',
          ),
        );

    final subGroup2 = WhereConditionGroup()
        .and(
          ColumnWhereCondition(
            column: columns.width,
            operator: '<',
            value: '200',
          ),
        )
        .or(
          ColumnWhereCondition(
            column: columns.width,
            operator: '>',
            value: '1000',
          ),
        );

    final dateColumn = columns.createDate;
    final date = DateTime.now().subtract(const Duration(days: 30));

    final dateItem = DateColumnWhereCondition(
      column: dateColumn,
      operator: '>',
      value: date,
    );

    final whereGroup = WhereConditionGroup()
        .and(
          subGroup1,
        )
        .and(
          subGroup2,
        )
        .and(dateItem);

    final filter = AdvancedCustomFilter()
        .addOrderBy(
          column: columns.createDate,
          isAsc: false,
        )
        .addWhereCondition(whereGroup);

    return filter;
  }
}
