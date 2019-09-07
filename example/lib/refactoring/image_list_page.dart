import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryContentListPage extends StatefulWidget {
  final AssetPathEntity path;

  const GalleryContentListPage({Key key, this.path}) : super(key: key);
  @override
  _GalleryContentListPageState createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  static Widget _loadWidget = Center(
    child: SizedBox.fromSize(
      size: Size.square(30),
      child: Platform.isIOS
          ? CupertinoActivityIndicator()
          : CircularProgressIndicator(),
    ),
  );

  List<AssetEntity> list = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${path.name}"),
      ),
      body: GridView.builder(
        itemBuilder: _buildItem,
        itemCount: list.length,
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = list[index];
    return AspectRatio(
      aspectRatio: 1,
      child: FutureBuilder<Uint8List>(
        future: Plugin().getThumb(id: item.id, width: 130, height: 130),
        // future: Plugin().getOriginBytes(item.id),
        builder: (context, snapshot) {
          Widget w;
          if (snapshot.hasError) {
            w = Center(
              child: Text("load error"),
            );
          }
          if (snapshot.hasData) {
            w = FittedBox(
              fit: BoxFit.cover,
              child: Image.memory(
                snapshot.data,
              ),
            );
          } else {
            w = Center(
              child: _loadWidget,
            );
          }

          return w;
        },
      ),
    );
  }

  void initData() async {
    final list = await path.getAssetListPaged(0, 40);

    this.list.addAll(list);
    setState(() {});
  }
}
