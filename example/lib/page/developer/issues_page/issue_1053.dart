import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import 'issue_index_page.dart';

class Issus1053 extends StatefulWidget {
  const Issus1053({super.key});

  @override
  State<Issus1053> createState() => _Issus1053State();
}

class _Issus1053State extends State<Issus1053> with IssueBase<Issus1053> {
  Future<void> _requestPermission() async {
    if (checkStatus.isEmpty) {
      showToast('Please select at least one type');
      return;
    }

    final requestType = RequestType.fromTypes(checkStatus);

    final PermissionState status = await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: requestType,
          mediaLocation: false,
        ),
      ),
    );
    addLog('status: $status');
  }

  @override
  List<TargetPlatform>? get supportPlatforms => [
        TargetPlatform.android,
      ];

  List<RequestType> checkStatus = [];

  @override
  Widget build(BuildContext context) {
    return buildScaffold([
      for (final item in RequestType.values) _buildCheck(item),
      buildButton(
        'Test requestPermissionExtend',
        _requestPermission,
      ),
      buildLogWidget(),
    ]);
  }

  @override
  int get issueNumber => 1053;

  Widget _buildCheck(RequestType item) {
    String title = '';
    switch (item.value) {
      case 1:
        title = 'image';
        break;
      case 2:
        title = 'video';
        break;
      case 4:
        title = 'audio';
        break;
    }

    return CheckboxListTile(
      title: Text(title),
      value: checkStatus.contains(item),
      onChanged: (checked) {
        if (checked == true) {
          checkStatus.add(item);
        } else {
          checkStatus.remove(item);
        }
        setState(() {});
      },
    );
  }
}
