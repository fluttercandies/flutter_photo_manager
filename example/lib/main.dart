import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'photos.dart';

void main() => runApp(MaterialApp(
      home: new MyApp(),
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

const _cacheIosAssetId = "106E99A1-4F6A-45A2-B320-B0AD4A8E8473/L0/001";

class _MyAppState extends State<MyApp> {
  var pathList = <AssetPathEntity>[];

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Plugin example app'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: _onlyImage,
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: _onlyVideo,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSetting,
          ),
          IconButton(
            icon: Icon(Icons.cached),
            onPressed: showImageDialogWithAssetId,
          ),
        ],
      ),
      body: new ListView.builder(
        itemBuilder: _buildItem,
        itemCount: pathList.length,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: getImages,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    var data = pathList[index];
    return _buildWithData(data);
  }

  Widget _buildWithData(AssetPathEntity data) {
    return GestureDetector(
      child: ListTile(
        title: Text(data.name),
      ),
      onTap: () async {
        var list = await data.assetList;
        print("开启的相册为:${data.name} , 数量为 : ${list.length} , list = $list");
        var page = PhotoPage(
          pathEntity: data,
          photos: list,
        );
        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => page));
      },
    );
  }

  // This is an example of how to build album preview.
  Widget _buildHasPreviewItem(BuildContext context, int index) {
    var data = pathList[index];
    Widget widget = FutureBuilder<List<AssetEntity>>(
      future: data.assetList,
      builder:
          (BuildContext context, AsyncSnapshot<List<AssetEntity>> snapshot) {
        var assetList = snapshot.data;
        if (assetList == null || assetList.isEmpty) {
          return Container(
            child: Text('loading'),
          );
        }
        AssetEntity asset = assetList[0];
        return _buildPreview(asset);
      },
    );
    return widget;
  }

  Widget _buildPreview(AssetEntity asset) {
    return FutureBuilder<Uint8List>(
      future: asset.thumbDataWithSize(200, 200),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.data != null) {
          return Image.memory(snapshot.data);
        }
        return Container();
      },
    );
  }

  void _openSetting() {
    PhotoManager.openSetting();
  }

  void getImages() async {
    var result = await PhotoManager.requestPermission();
    if (!(result == true)) {
      print("未授予权限");
      return;
    }

    print("wait scan");
    List<AssetPathEntity> list =
        await PhotoManager.getAssetPathList(hasVideo: true);

    pathList.clear();
    pathList.addAll(list);
    setState(() {});

    // var r = await ImagePicker.pickImages(source: ImageSource.gallery, numberOfItems: 10);
    // print(r);
  }

  void _onlyVideo() async {
    var pathList = await PhotoManager.getVideoAsset();
    updateDatas(pathList);
  }

  void _onlyImage() async {
    var pathList = await PhotoManager.getImageAsset();
    updateDatas(pathList);
  }

  updateDatas(List<AssetPathEntity> list) {
    pathList.clear();
    pathList.addAll(list);
    setState(() {});
  }

  void showImageDialogWithAssetId() async {
    String id;

    if (Platform.isIOS) {
      id = _cacheIosAssetId;
    }

    var asset = await createAssetEntityWithId(id);

    showDialog(
      context: context,
      builder: (ctx) {
        return GestureDetector(
          child: _buildPreview(asset),
          onTap: () => Navigator.pop(ctx),
        );
      },
    );
  }
}
