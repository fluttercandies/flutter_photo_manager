import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/custom_filter/path_list.dart';

import 'custom_filter/advance_filter_page.dart';
import 'custom_filter/custom_filter_sql_gif_image.dart';
import 'custom_filter/custom_filter_sql_page.dart';
import 'custom_filter/filter_assets_page.dart';
import 'custom_filter/include_hidden_test_page.dart';

class CustomFilterExamplePage extends StatelessWidget {
  const CustomFilterExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildItem(String title, Widget target) {
      return ListTile(
        title: Text(title),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => target));
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Filter Example'),
      ),
      body: Center(
        child: Column(
          children: [
            buildItem(
              'Custom Filter with sql',
              CustomFilterSqlPage(
                builder: (BuildContext context, CustomFilter filter) {
                  return FilterPathList(filter: filter);
                },
              ),
            ),
            buildItem(
              'Advanced Custom Filter',
              AdvancedCustomFilterPage(
                builder: (BuildContext context, CustomFilter filter) {
                  return FilterPathList(filter: filter);
                },
              ),
            ),
            buildItem(
              'Custom Filter sql assets',
              CustomFilterSqlPage(
                builder: (BuildContext context, CustomFilter filter) {
                  return FilterAssetsContent(filter: filter);
                },
              ),
            ),
            buildItem(
              'Custom filter SQL for only GIF images',
              CustomFilterSqlGIFImage(
                builder: (BuildContext context, CustomFilter filter) {
                  return FilterAssetsContent(filter: filter);
                },
              ),
            ),
            buildItem(
              'Advanced Custom Filter assets',
              AdvancedCustomFilterPage(
                builder: (BuildContext context, CustomFilter filter) {
                  return FilterAssetsContent(filter: filter);
                },
              ),
            ),
            if (Platform.isIOS || Platform.isMacOS)
              buildItem(
                'Include hidden test',
                const IncludeHiddenTestPage(),
              ),
          ],
        ),
      ),
    );
  }
}
