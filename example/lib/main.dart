import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'photos.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var pathList = <AssetPathEntity>[];

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
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
            List<AssetPathEntity> list = await PhotoManager.getAssetPathList();

            // print("list = $list");
            pathList.clear();
            pathList.addAll(list);
            setState(() {});

            // var r = await ImagePicker.pickImages(source: ImageSource.gallery, numberOfItems: 10);
            // print(r);
          },
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    var data = pathList[index];
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

  void _openSetting() {
    PhotoManager.openSetting();
  }
}
