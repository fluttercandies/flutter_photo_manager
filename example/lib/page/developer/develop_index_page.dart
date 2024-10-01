import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/developer/android/column_names_page.dart';
import 'package:photo_manager_example/page/developer/custom_filter_page.dart';
import 'package:provider/provider.dart';

import '../../model/photo_provider.dart';
import '../../util/log.dart';
import '../../util/log_export.dart';
import 'create_entity_by_id.dart';
import 'dev_title_page.dart';
import 'ios/create_folder_example.dart';
import 'ios/edit_asset.dart';
import 'issues_page/issue_index_page.dart';
import 'permission_state_page.dart';
import 'remove_all_android_not_exists_example.dart';
import 'verbose_log_page.dart';

class DeveloperIndexPage extends StatefulWidget {
  const DeveloperIndexPage({super.key});

  @override
  State<DeveloperIndexPage> createState() => _DeveloperIndexPageState();
}

class _DeveloperIndexPageState extends State<DeveloperIndexPage> {
  static const exampleMovUrl =
      'https://cdn.jsdelivr.net/gh/ExampleAssets/ExampleAsset@master/preview_0.mov';

  static const exampleHeicUrl =
      'https://cdn.jsdelivr.net/gh/ExampleAssets/ExampleAsset@master/preview_0.heic';

  Widget _buildVerboseLogSwitch(BuildContext conetxt) {
    final PhotoProvider provider = context.watch<PhotoProvider>();
    final bool verboseLog = provider.showVerboseLog;
    return CheckboxListTile(
      title: const Text('Verbose log'),
      value: verboseLog,
      onChanged: (value) async {
        provider.changeVerboseLog(value!);
        setState(() {});

        if (verboseLog) {
          final path = await PMVerboseLogUtil.shared.getLogFilePath();
          PhotoManager.setLog(true, verboseFilePath: path);
        } else {
          PhotoManager.setLog(false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('develop index'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          _buildVerboseLogSwitch(context),
          ElevatedButton(
            onPressed: () => navToWidget(const VerboseLogPage()),
            child: const Text('Show verbose log'),
          ),
          ElevatedButton(
            onPressed: () => navToWidget(const CustomFilterPage()),
            child: const Text('Custom filter'),
          ),
          if (Platform.isAndroid)
            ElevatedButton(
              onPressed: () => navToWidget(const ColumnNamesPage()),
              child: const Text('Android: column names'),
            ),
          ElevatedButton(
            onPressed: () => navToWidget(const PermissionStatePage()),
            child: const Text('Show permission state page'),
          ),
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
            onPressed: _requestPermission,
            child: const Text('Request permission'),
          ),
          ElevatedButton(
            onPressed: _upload,
            child: const Text('upload file to local to test EXIF.'),
          ),
          ElevatedButton(
            onPressed: _saveVideo,
            child: const Text('Save video to photos.'),
          ),
          if (Platform.isIOS || Platform.isMacOS)
            ElevatedButton(
              onPressed: _saveLivePhoto,
              child: const Text('Save live photo'),
            ),
          if (Platform.isIOS || Platform.isMacOS)
            ElevatedButton(
              onPressed: _testNeedTitle,
              child: const Text('Show needTitle in console'),
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
        ]
            .map(
              (e) => Container(
                padding: const EdgeInsets.all(3.0),
                height: 44,
                child: e,
              ),
            )
            .toList(),
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

    resp.listen(
      (List<int> data) {
        f.writeAsBytesSync(data, mode: FileMode.append);
      },
      onDone: () async {
        client.close();
        Log.d('the video file length = ${f.lengthSync()}');
        final AssetEntity result = await PhotoManager.editor.saveVideo(
          f,
          title: title,
        );
        Log.d('result : ${(await result.originFile)?.path}');
      },
    );
  }

  Future<File?> _downloadFile(String url) async {
    final HttpClient client = HttpClient();
    final HttpClientRequest req = await client.getUrl(Uri.parse(url));
    final extName = url.split('.').last;
    final HttpClientResponse resp = await req.close();
    final Directory tmp = Directory.systemTemp;
    final String title = '${DateTime.now().millisecondsSinceEpoch}.$extName';
    final File f = File('${tmp.absolute.path}/$title');
    if (f.existsSync()) {
      f.deleteSync();
    }
    f.createSync();

    final IOSink sink = f.openWrite();
    await sink.addStream(resp);
    await sink.flush();
    await sink.close();
    return f;
  }

  Future<void> _saveLivePhoto() async {
    final File? imgFile = await _downloadFile(exampleHeicUrl);
    print(
      'The image download to ${imgFile?.path}, length: ${imgFile?.lengthSync()}',
    );
    final File? videoFile = await _downloadFile(exampleMovUrl);
    print(
      'The video download to ${videoFile?.path}, length: ${videoFile?.lengthSync()}',
    );

    try {
      if (imgFile == null || videoFile == null) {
        return;
      }
      final assets = await PhotoManager.editor.darwin.saveLivePhoto(
        imageFile: imgFile,
        videoFile: videoFile,
        title: 'preview_0',
      );
      print('save live photo result : ${assets.id}');
    } finally {
      imgFile?.deleteSync();
      videoFile?.deleteSync();
      print('The temp file has been deleted.');
    }
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

  Future<void> _testNeedTitle() async {
    final status = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );

    if (!status.isAuth) {
      showToast('Cannot have permission');
      return;
    }

    Future<void> showInfo(String title, PMFilter option) async {
      final assetList = await PhotoManager.getAssetListPaged(
        page: 0,
        pageCount: 20,
        filterOption: option,
        type: RequestType.image,
      );

      print('Show info for option: $title');

      for (final asset in assetList) {
        print('asset title: ${asset.title}');
      }
    }

    final option1 = FilterOptionGroup(
      imageOption: const FilterOption(
        needTitle: true,
      ),
    );

    await showInfo('option1', option1);

    final PMFilter option2 = AdvancedCustomFilter()..needTitle = true;
    await showInfo('option2', option2);
  }

  Future<void> _requestPermission() async {
    final authStatus = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );
    print('auth status: $authStatus');
  }

  @override
  void dispose() {
    if (_isNotify) {
      PhotoManager.removeChangeCallback(_callback);
    }
    super.dispose();
  }
}
