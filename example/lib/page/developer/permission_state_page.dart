import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionStatePage extends StatefulWidget {
  const PermissionStatePage({super.key});

  @override
  State<PermissionStatePage> createState() => _PermissionStatePageState();
}

class _PermissionStatePageState extends State<PermissionStatePage> {
  List<RequestType> types = RequestType.values;
  RequestType get _selectedType {
    return RequestType.fromTypes(types);
  }

  PermissionState? _permissionState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission State'),
      ),
      body: ListView(
        children: [
          Column(
            children: RequestType.values.map((RequestType type) {
              return CheckboxListTile(
                title: Text(type.toString().split('.').last),
                value: _selectedType.containsType(type),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      types.add(type);
                    } else {
                      types.remove(type);
                    }
                  });
                },
              );
            }).toList(),
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
        ],
      ),
    );
  }

  Future<void> _requestPermission() async {
    final PermissionRequestOption option = _option();
    final result = await PhotoManager.requestPermissionExtend(requestOption: option);
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