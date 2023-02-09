import 'package:flutter/material.dart';

import 'custom_filter/advance_filter_page.dart';
import 'custom_filter/custom_filter_sql_page.dart';

class CustomFilterExamplePage extends StatelessWidget {
  const CustomFilterExamplePage({Key? key}) : super(key: key);

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
            buildItem('Custom Filter with sql', const CustomFilterSqlPage()),
            buildItem(
                'Advanced Custom Filter', const AdvancedCustomFilterPage()),
          ],
        ),
      ),
    );
  }
}
