import 'package:flutter/material.dart';
import 'package:image_scanner/image_scanner.dart';
import 'package:image_scanner_example/photos.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var pathList = <ImageParentPath>[];

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
            var result = await ImageScanner.requestPermission();
            if (!(result == true)) {
              print("未授予权限");
              return;
            }

            print("wait scan");
            var list = await ImageScanner.getImagePathList();

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
        var list = await data.imageList;
        var page = PhotoPage(
          pathEntity: data,
          photos: list,
        );
        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => page));
      },
    );
  }

  void _openSetting() {
    ImageScanner.openSetting();
  }
}
