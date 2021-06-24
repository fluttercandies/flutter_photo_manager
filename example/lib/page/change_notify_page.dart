import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

class ChangeNotifyExample extends StatefulWidget {
  const ChangeNotifyExample({Key? key}) : super(key: key);

  @override
  _ChangeNotifyExampleState createState() => _ChangeNotifyExampleState();
}

class _ChangeNotifyExampleState extends State<ChangeNotifyExample> {
  void initState() {
    super.initState();
    PhotoManager.addChangeCallback(_onChange);
  }

  void dispose() {
    PhotoManager.removeChangeCallback(_onChange);
    super.dispose();
  }

  List<String> logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChangeNotifyExample'),
      ),
      body: Container(
        child: Column(
          children: [
            _buildCheck(),
            if (Platform.isIOS)
              ElevatedButton(
                onPressed: () {
                  PhotoManager.presentLimited();
                },
                child: Text('Present limit'),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  reverse: true,
                  itemBuilder: (BuildContext context, int index) {
                    final log = logs[index];
                    return Text(log);
                  },
                  itemCount: logs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheck() {
    return StreamBuilder<bool>(
      builder: (context, snapshot) {
        return CheckboxListTile(
          title: Text('Current notify state'),
          value: snapshot.data,
          onChanged: (newValue) {
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
    final log = '${value.method}: ${value.arguments}';
    logs.add(log);
    setState(() {});
  }
}
