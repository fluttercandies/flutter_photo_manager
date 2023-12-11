import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

class ChangeNotifyExample extends StatefulWidget {
  const ChangeNotifyExample({super.key});

  @override
  State<ChangeNotifyExample> createState() => _ChangeNotifyExampleState();
}

class _ChangeNotifyExampleState extends State<ChangeNotifyExample> {
  @override
  void initState() {
    super.initState();
    PhotoManager.addChangeCallback(_onChange);
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onChange);
    super.dispose();
  }

  List<String> logs = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChangeNotifyExample'),
      ),
      body: Column(
        children: <Widget>[
          _buildCheck(),
          if (Platform.isIOS)
            ElevatedButton(
              onPressed: () {
                PhotoManager.presentLimited();
              },
              child: const Text('Present limit'),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                reverse: true,
                itemBuilder: (BuildContext context, int index) {
                  final String log = logs[index];
                  return Text(log);
                },
                itemCount: logs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheck() {
    return StreamBuilder<bool>(
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        return CheckboxListTile(
          title: const Text('Current notify state'),
          value: snapshot.data,
          onChanged: (bool? newValue) {
            if (newValue == true) {
              PhotoManager.startChangeNotify();
            } else {
              PhotoManager.stopChangeNotify();
            }
          },
        );
      },
      initialData: PhotoManager.notifyingOfChange,
      stream: PhotoManager.notifyStream,
    );
  }

  void _onChange(MethodCall value) {
    final String log = '${value.method}: ${value.arguments}';
    logs.add(log);
    setState(() {});
  }
}
