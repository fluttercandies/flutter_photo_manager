import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class RemoveAndroidNotExistsExample extends StatefulWidget {
  const RemoveAndroidNotExistsExample({super.key});

  @override
  State<RemoveAndroidNotExistsExample> createState() =>
      _RemoveAndroidNotExistsExampleState();
}

class _RemoveAndroidNotExistsExampleState
    extends State<RemoveAndroidNotExistsExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove android not exists assets.'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Click and see android logcat log.'),
              onPressed: () {
                PhotoManager.editor.android.removeAllNoExistsAsset();
              },
            ),
          ],
        ),
      ),
    );
  }
}
