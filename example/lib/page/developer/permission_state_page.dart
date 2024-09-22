import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

extension on List<Widget> {
  List<Widget> paddingAll(double padding) {
    return map((e) => Padding(padding: EdgeInsets.all(padding), child: e))
        .toList();
  }
}

class PermissionStatePage extends StatefulWidget {
  const PermissionStatePage({super.key});

  @override
  State<PermissionStatePage> createState() => _PermissionStatePageState();
}

class _PermissionStatePageState extends State<PermissionStatePage> {
  List<int> types = [
    RequestType.image.value,
    RequestType.video.value,
  ];

  RequestType get _selectedType {
    return RequestType.fromTypes(types.map((e) => RequestType(e)).toList());
  }

  PermissionState? _permissionState;

  IosAccessLevel _iosAccessLevel = IosAccessLevel.readWrite; // 添加这一行

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission State'),
      ),
      body: ListView(
        children: [
          if (Platform.isAndroid)
            Column(
              children: RequestType.values.map((RequestType type) {
                return CheckboxListTile(
                  title: Text(type.toString().split('.').last),
                  value: types.contains(type.value),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        types.add(type.value);
                      } else {
                        types.remove(type.value);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          if (Platform.isIOS)
            Column(
              children: [
                Text('iOS Access Level: $_iosAccessLevel'),
                DropdownButton<IosAccessLevel>(
                  value: _iosAccessLevel,
                  onChanged: (IosAccessLevel? value) {
                    setState(() {
                      _iosAccessLevel = value!;
                    });
                  },
                  items: IosAccessLevel.values.map((IosAccessLevel value) {
                    return DropdownMenuItem<IosAccessLevel>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ElevatedButton(
            onPressed: _requestPermission,
            child: const Text('Request Permission'),
          ),
          ElevatedButton(
            onPressed: _getPermissionState,
            child: const Text('Get Permission State'),
          ),
          if (_permissionState != null)
            Text('Current Permission State: $_permissionState'),
        ].paddingAll(16),
      ),
    );
  }

  Future<void> _requestPermission() async {
    final PermissionRequestOption option = _option();
    final result =
        await PhotoManager.requestPermissionExtend(requestOption: option);
    setState(() {
      _permissionState = result;
    });
  }

  PermissionRequestOption _option() {
    final type = _selectedType;
    final PermissionRequestOption option = PermissionRequestOption(
      androidPermission: AndroidPermission(type: type, mediaLocation: false),
      iosAccessLevel: IosAccessLevel.readWrite,
      ohosPermissions: const [],
    );
    return option;
  }

  Future<void> _getPermissionState() async {
    final PermissionRequestOption option = _option();
    final state = await PhotoManager.getPermissionState(requestOption: option);
    setState(() {
      _permissionState = state;
    });
  }
}
