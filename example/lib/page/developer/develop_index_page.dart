import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';

import '../../util/log.dart';
import 'create_entity_by_id.dart';
import 'dev_title_page.dart';
import 'ios/create_folder_example.dart';
import 'ios/edit_asset.dart';
import 'issues_page/issue_index_page.dart';
import 'remove_all_android_not_exists_example.dart';

class DeveloperIndexPage extends StatefulWidget {
  const DeveloperIndexPage({Key? key}) : super(key: key);

  @override
  State<DeveloperIndexPage> createState() => _DeveloperIndexPageState();
}

class _DeveloperIndexPageState extends State<DeveloperIndexPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('develop index'),
      ),
      body: ListView(
        children: <Widget>[
          ElevatedButton(
            child: const Text('Show iOS create folder example.'),
            onPressed: () => navToWidget(const CreateFolderExample()),
          ),
          ElevatedButton(
            child: const Text('Test edit image'),
            onPressed: () => navToWidget(const EditAssetPage()),
          ),
          ElevatedButton(
            child: const Text('Show Android remove not exists asset example.'),
            onPressed: () => navToWidget(const RemoveAndroidNotExistsExample()),
          ),
          ElevatedButton(
            onPressed: _upload,
            child: const Text('upload file to local to test EXIF.'),
          ),
          ElevatedButton(
            onPressed: _saveVideo,
            child: const Text('Save video to photos.'),
          ),
          ElevatedButton(
            onPressed: _navigatorSpeedOfTitle,
            child: const Text('Open test title page'),
          ),
          ElevatedButton(
            onPressed: _openSetting,
            child: const Text('Open setting.'),
          ),
          ElevatedButton(
            child: const Text('Create Entity ById'),
            onPressed: () => navToWidget(const CreateEntityById()),
          ),
          ElevatedButton(
            onPressed: _clearFileCaches,
            child: const Text('Clear file caches'),
          ),
          ElevatedButton(
            onPressed: _requestPermssionExtend,
            child: const Text('Request permission extend'),
          ),
          ElevatedButton(
            onPressed: _openIssue,
            child: const Text('Open issue page'),
          ),
          if (Platform.isIOS)
            ElevatedButton(
              onPressed: _persentLimited,
              child: const Text('PresentLimited'),
            ),
        ],
      ),
    );
  }

  Future<void> _upload() async {
    final List<AssetPathEntity> path = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    final List<AssetEntity> assetList = await path[0].getAssetListRange(
      start: 0,
      end: 5,
    );
    final AssetEntity asset = assetList[0];

    // for (final tmpAsset in assetList) {
    //   await tmpAsset.originFile;
    // }

    final File? file = await asset.originFile;
    if (file == null) {
      return;
    }

    Log.d('file length = ${file.lengthSync()}');

    final http.Client client = http.Client();
    final http.MultipartRequest req = http.MultipartRequest(
      'post',
      Uri.parse('http://172.16.100.7:10001/upload/file'),
    );

    req.files
        .add(await http.MultipartFile.fromPath('file', file.absolute.path));

    req.fields['type'] = 'jpg';

    final http.StreamedResponse response = await client.send(req);
    final String body = await utf8.decodeStream(response.stream);
    Log.d(body);
  }

  Future<void> _saveVideo() async {
    // String url = "http://172.16.100.7:5000/QQ20181114-131742-HD.mp4";
    const String url =
        'http://172.16.100.7:5000/Kapture%202019-11-20%20at%2017.07.58.mp4';

    final HttpClient client = HttpClient();
    final HttpClientRequest req = await client.getUrl(Uri.parse(url));
    final HttpClientResponse resp = await req.close();
    final Directory tmp = Directory.systemTemp;
    final String title = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final File f = File('${tmp.absolute.path}/$title');
    if (f.existsSync()) {
      f.deleteSync();
    }
    f.createSync();

    resp.listen((List<int> data) {
      f.writeAsBytesSync(data, mode: FileMode.append);
    }, onDone: () async {
      client.close();
      Log.d('the video file length = ${f.lengthSync()}');
      final AssetEntity? result =
          await PhotoManager.editor.saveVideo(f, title: title);
      if (result != null) {
        Log.d('result : ${(await result.originFile)?.path}');
      } else {
        Log.d('result is null');
      }
    });
  }

  void _navigatorSpeedOfTitle() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          const DevelopingExample widget = DevelopingExample();
          return widget;
        },
      ),
    );
  }

  void navToWidget(Widget widget) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => widget),
    );
  }

  void _openIssue() {
    navToWidget(const IssuePage());
  }

  void _openSetting() {
    PhotoManager.openSetting();
  }

  void _clearFileCaches() {
    PhotoManager.clearFileCache();
  }

  Future<void> _requestPermssionExtend() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    Log.d('result --- state: $state');
  }

  bool _isNotify = false;

  Future<void> _persentLimited() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps == PermissionState.authorized) {
      return;
    }
    if (!_isNotify) {
      _isNotify = true;
      PhotoManager.addChangeCallback(_callback);
    }
    PhotoManager.startChangeNotify();
    await PhotoManager.presentLimited();
  }

  void _callback(MethodCall call) {
    Log.d('on change ${call.method} ${call.arguments}');
    PhotoManager.removeChangeCallback(_callback);
    _isNotify = false;
  }

  @override
  void dispose() {
    if (_isNotify) {
      PhotoManager.removeChangeCallback(_callback);
    }
    super.dispose();
  }
}
