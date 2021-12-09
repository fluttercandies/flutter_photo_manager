import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ChangeNotifyExample extends StatefulWidget {
  const ChangeNotifyExample({Key? key}) : super(key: key);

  @override
  _ChangeNotifyExampleState createState() => _ChangeNotifyExampleState();
}

class _ChangeNotifyExampleState extends State<ChangeNotifyExample> {
  StreamSubscription<NotifyChangeInfo>? notifySubscription;

  @override
  void initState() {
    super.initState();
    PhotoManager.onChangeNotify.listen((info) {
      setState(() {
        logs.add(info.toString());
      });
    });
  }

  @override
  void dispose() {
    notifySubscription?.cancel();
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
}
