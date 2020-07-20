import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

class UserStreamPage extends StatefulWidget {
  final AssetEntity asset;

  const UserStreamPage({
    Key key,
    this.asset,
  }) : super(key: key);

  @override
  _UserStreamPageState createState() => _UserStreamPageState();
}

class _UserStreamPageState extends State<UserStreamPage> {
  AssetEntity get asset => widget.asset;
  AssetOriginStream originStream;
  File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Use stream'),
      ),
      body: ListView(
        children: <Widget>[
          RaisedButton(
            child: Text('open stream'),
            onPressed: openStream,
          ),
          RaisedButton(
            child: Text('start with write file'),
            onPressed: start,
          ),
          // TODO Add big file and upload, test case
        ],
      ),
    );
  }

  void openStream() async {
    if (originStream != null) {
      showToast('The stream already create');
      return;
    }
    originStream = await asset.createOriginByteStream();
  }

  void start() async {
    if (originStream == null) {
      showToast('You must create originStream first!');
      return;
    }
    if (originStream.running) {
      showToast('The origin stream already running');
      return;
    }

    Directory tmpDir;

    if (Platform.isIOS) {
      tmpDir = await getTemporaryDirectory();
    } else if (Platform.isAndroid) {
      tmpDir = (await getExternalCacheDirectories())[0];
    } else {
      showToast('Not support the platform');
      return;
    }

    final title = await asset.titleAsync;
    file = File('${tmpDir.absolute.path}/$title');

    if (file.existsSync()) {
      file.deleteSync();
    }

    originStream.completionNotifier.addListener(onCompletion);

    originStream.stream.listen((event) {
      file.writeAsBytesSync(event, mode: FileMode.append, flush: true);
      print('write ${event.length} bytes');
    });

    originStream.start();
  }

  @override
  void dispose() {
    file = null;
    originStream?.release();
    originStream = null;
    super.dispose();
  }

  void onCompletion() {
    print('The ${file.absolute.path} written onCompletion');
    originStream.completionNotifier.removeListener(onCompletion);
  }
}
