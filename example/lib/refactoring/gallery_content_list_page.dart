import 'dart:typed_data';

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

  List<AssetEntity> list = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
    print(item.id);
    return AspectRatio(
      aspectRatio: 1,
      child: FutureBuilder<Uint8List>(
        future: Plugin().getThumb(id: item.id, width: 130, height: 130),
        // future: Plugin().getOriginBytes(item.id),
        builder: (context, snapshot) {
          Widget w;
          if (snapshot.hasError) {
            w = Text("error");
          }
          if (snapshot.hasData) {
            w = Image.memory(snapshot.data);
          } else {
            w = Text("no data");
          }

          return Stack(
            children: <Widget>[
              w,
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 80,
                  height: 20,
                  child: Text(item.typeInt.toString()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void initData() async {
    final list = await path.getAssetListPaged(0, 1000);

    print(list.length);

    this.list.addAll(list);
    setState(() {});
  }
}
