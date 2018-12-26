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

class _MyAppState extends State<MyApp> {
  var pathList = <AssetPathEntity>[];

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Plugin example app'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings_applications),
            onPressed: _openSetting,
          ),
        ],
      ),
      body: new ListView.builder(
        itemBuilder: _buildItem,
        itemCount: pathList.length,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () async {
          var result = await PhotoManager.requestPermission();
          if (!(result == true)) {
            print("未授予权限");
            return;
          }

          print("wait scan");
          List<AssetPathEntity> list = await PhotoManager.getAssetPathList(hasVideo: true);

          pathList.clear();
          pathList.addAll(list);
          setState(() {});

          // var r = await ImagePicker.pickImages(source: ImageSource.gallery, numberOfItems: 10);
          // print(r);
        },
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
        print("开启的相册为:${data.name} , 数量为 : ${list.length}");
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
      builder: (BuildContext context, AsyncSnapshot<List<AssetEntity>> snapshot) {
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
}
