import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';

import 'issue_index_page.dart';

class Issue1025Page extends StatefulWidget {
  const Issue1025Page({Key? key}) : super(key: key);

  @override
  State<Issue1025Page> createState() => _Issue1025PageState();
}

class _Issue1025PageState extends State<Issue1025Page>
    with IssueBase<Issue1025Page> {
  String log = '';

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      [
        buildButton('Test for ignore permission', _testForIgnorePermission),
        Expanded(child: Text(log)),
      ],
    );
  }

  @override
  int get issueNumber => 1025;

  Future<void> _testForIgnorePermission() async {
    await PhotoManager.setIgnorePermissionCheck(true);
    setState(() {
      log = 'setIgnorePermissionCheck(true) success' '\n$log';
    });
  }
}
