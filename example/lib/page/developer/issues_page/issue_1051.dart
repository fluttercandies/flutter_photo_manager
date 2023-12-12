import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/developer/issues_page/issue_index_page.dart';

class Issus1051 extends StatefulWidget {
  const Issus1051({super.key});

  @override
  State<Issus1051> createState() => _Issus1051State();
}

class _Issus1051State extends State<Issus1051> with IssueBase<Issus1051> {
  Future<void> _test() async {
    final status = await PhotoManager.requestPermissionExtend();
    if (status.hasAccess) {
      await PhotoManager.presentLimited();
      print('present limited');
    }

    print('status: $status');
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold([
      buildButton(
        'Test presentLimited',
        _test,
      ),
    ]);
  }

  @override
  int get issueNumber => 1051;

  @override
  List<TargetPlatform>? get supportPlatforms => [
        TargetPlatform.android,
      ];
}
