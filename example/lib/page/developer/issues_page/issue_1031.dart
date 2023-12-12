import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';

import 'issue_index_page.dart';

class Issue1031Page extends StatefulWidget {
  const Issue1031Page({super.key});

  @override
  State<Issue1031Page> createState() => _Issue1031PageState();
}

class _Issue1031PageState extends State<Issue1031Page>
    with IssueBase<Issue1031Page> {
  String log = '';

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      [
        buildButton('Test for permission', _testForIgnorePermission),
        Expanded(child: Text(log)),
      ],
    );
  }

  @override
  int get issueNumber => 1031;

  Future<void> _testForIgnorePermission() async {
    final permission = await PhotoManager.requestPermissionExtend();
    log = 'permission: $permission' '\n$log';
    log = 'isAuth: ${permission.isAuth}' '\n$log';
    setState(() {});
  }
}
